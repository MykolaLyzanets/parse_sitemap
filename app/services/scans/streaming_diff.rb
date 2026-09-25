# frozen_string_literal: true

require 'zlib'

module Scans
  class StreamingDiff
    Result = Data.define(
      :total_count,
      :added_count,
      :removed_count,
      :unchanged_count,
      :current_snapshot_gz_path,
      :added_snapshot_gz_path,
      :removed_snapshot_gz_path
    )

    def self.call(site:, scan_id: nil, chunk_rows: SnapshotFile::DEFAULT_CHUNK_ROWS, &block)
      new(site: site, scan_id: scan_id, chunk_rows: chunk_rows).call(&block)
    end

    def initialize(site:, scan_id: nil, chunk_rows: SnapshotFile::DEFAULT_CHUNK_ROWS)
      @site = site
      @scan_id = scan_id
      @chunk_rows = chunk_rows
    end

    def call(&block)
      raise ArgumentError, 'block required' unless block

      current_sorted = sorted_tempfile('current')
      merge_started = monotonic_now
      unique_count = SnapshotFile.write_sorted_from_normalized_urls(current_sorted.path, chunk_rows: chunk_rows, &block)
      log_phase(
        "Парсинг завершено. Злиття chunk-ів: #{unique_count} унікальних URL " \
        "(#{elapsed_seconds(merge_started)}s, TSV #{file_size_mb(current_sorted.path)} MB)"
      )

      current_gz = gz_tempfile('current')
      gzip_started = monotonic_now
      SnapshotFile.gzip_file(current_sorted.path, current_gz.path)
      log_phase(
        "Gzip поточного snapshot: #{file_size_mb(current_gz.path)} MB (#{elapsed_seconds(gzip_started)}s)"
      )

      added_gz = gz_tempfile('added')
      removed_gz = gz_tempfile('removed')

      previous_path = SnapshotFile.uploader_path(site.snapshot)
      diff_started = monotonic_now
      counts = if previous_path.present?
                 merge_sorted(previous_path, current_sorted.path, added_gz.path, removed_gz.path)
               else
                 first_scan(current_sorted.path, added_gz.path, removed_gz.path)
               end
      log_phase(
        "Diff завершено: +#{counts[:added]} −#{counts[:removed]} =#{counts[:unchanged]} " \
        "(total=#{counts[:total]}, #{elapsed_seconds(diff_started)}s)"
      )

      Result.new(
        total_count: counts[:total],
        added_count: counts[:added],
        removed_count: counts[:removed],
        unchanged_count: counts[:unchanged],
        current_snapshot_gz_path: current_gz.path,
        added_snapshot_gz_path: added_gz.path,
        removed_snapshot_gz_path: removed_gz.path
      )
    end

    private

    attr_reader :site, :scan_id, :chunk_rows

    def log_phase(message)
      return unless scan_id

      Log.info(site: site, scan_id: scan_id, message: message)
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def elapsed_seconds(started_at)
      (monotonic_now - started_at).round(1)
    end

    def file_size_mb(path)
      return 0 unless File.exist?(path)

      (File.size(path) / 1_048_576.0).round(1)
    end

    def first_scan(current_sorted_path, added_gz_path, removed_gz_path)
      SnapshotFile.gzip_file(current_sorted_path, added_gz_path)
      Zlib::GzipWriter.open(removed_gz_path) { |_| }

      total = SnapshotFile.count_entries(added_gz_path)
      { total: total, added: total, removed: 0, unchanged: 0 }
    end

    def merge_sorted(previous_gz_path, current_sorted_path, added_gz_path, removed_gz_path)
      added = 0
      removed = 0
      unchanged = 0

      previous_enum = enum_from_gz(previous_gz_path)
      current_enum = File.foreach(current_sorted_path)

      prev = take_next(previous_enum)
      curr = take_next(current_enum)

      Zlib::GzipWriter.open(added_gz_path) do |added_gz|
        Zlib::GzipWriter.open(removed_gz_path) do |removed_gz|
          while prev || curr
            if prev && curr
              prev_digest, = prev.chomp.split(SnapshotFile::SEP, 2)
              curr_digest, = curr.chomp.split(SnapshotFile::SEP, 2)

              if prev_digest == curr_digest
                unchanged += 1
                prev = take_next(previous_enum)
                curr = take_next(current_enum)
              elsif prev_digest < curr_digest
                removed_gz.write(ensure_newline(prev))
                removed += 1
                prev = take_next(previous_enum)
              else
                added_gz.write(ensure_newline(curr))
                added += 1
                curr = take_next(current_enum)
              end
            elsif prev
              removed_gz.write(ensure_newline(prev))
              removed += 1
              prev = take_next(previous_enum)
            else
              added_gz.write(ensure_newline(curr))
              added += 1
              curr = take_next(current_enum)
            end
          end
        end
      end

      total = added + unchanged
      { total: total, added: added, removed: removed, unchanged: unchanged }
    end

    def enum_from_gz(path)
      Enumerator.new do |yielder|
        SnapshotFile.each_entry(path) do |digest, url|
          yielder << SnapshotFile.line(digest, url)
        end
      end
    end

    def take_next(enum)
      enum.next
    rescue StopIteration
      nil
    end

    def ensure_newline(row)
      row.end_with?("\n") ? row : "#{row}\n"
    end

    def sorted_tempfile(label)
      file = Tempfile.new(["snapshot-#{label}-", '.tsv'])
      file.binmode
      file
    end

    def gz_tempfile(label)
      file = Tempfile.new(["snapshot-#{label}-", '.gz'])
      file.binmode
      file.close
      file
    end
  end
end
