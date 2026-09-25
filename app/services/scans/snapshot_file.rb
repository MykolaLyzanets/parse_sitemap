# frozen_string_literal: true

require 'fileutils'
require 'zlib'
require 'open3'
require 'tempfile'

module Scans
  class SnapshotFile
    SEP = "\t"
    DEFAULT_CHUNK_ROWS = 50_000

    class << self
      def line(digest, url)
        "#{digest}#{SEP}#{url}\n"
      end

      def write_unsorted(path, normalized_urls)
        File.open(path, 'wb') do |file|
          normalized_urls.each do |url|
            file.write(line(SiteUrls::Normalizer.digest(url), url))
          end
        end
      end

      def write_sorted_from_normalized_urls(output_path, chunk_rows: DEFAULT_CHUNK_ROWS)
        unique_count = 0

        Dir.mktmpdir('snapshot-chunks-') do |chunk_dir|
          chunk_paths = []
          current_path = nil
          current_io = nil
          current_rows = 0

          emit = lambda do |normalized_url|
            if current_io.nil?
              current_path = File.join(chunk_dir, "chunk-#{chunk_paths.size}.tsv")
              current_io = File.open(current_path, 'wb')
            end

            current_io.write(line(SiteUrls::Normalizer.digest(normalized_url), normalized_url))
            current_rows += 1
            next unless current_rows >= chunk_rows

            finalize_chunk!(current_io, current_path, chunk_paths)
            current_io = nil
            current_path = nil
            current_rows = 0
          end

          yield emit

          finalize_chunk!(current_io, current_path, chunk_paths) if current_io
          unique_count = merge_sorted_chunks_dedup(chunk_paths, output_path)
        end

        unique_count
      end

      def sort_file(input_path, output_path)
        _stdout, stderr, status = Open3.capture3('sort', '-t', SEP, '-k1,1', input_path, '-o', output_path)
        raise "sort failed: #{stderr}" unless status.success?
      end

      def gzip_file(input_path, output_path)
        Zlib::GzipWriter.open(output_path) do |gz|
          File.foreach(input_path) { |row| gz.write(row) }
        end
      end

      def each_entry(path)
        return enum_for(:each_entry, path) unless File.exist?(path)

        Zlib::GzipReader.open(path) do |gz|
          gz.each_line do |row|
            digest, url = row.chomp.split(SEP, 2)
            next if digest.blank? || url.blank?

            yield digest, url
          end
        end
      end

      def each_url(path, page: 1, per_page: 100)
        offset = (page - 1) * per_page
        collected = []
        index = 0

        each_entry(path) do |_digest, url|
          if index >= offset && collected.size < per_page
            collected << url
          end
          index += 1
          break if collected.size >= per_page
        end

        collected
      end

      def count_entries(path)
        count = 0
        each_entry(path) { count += 1 }
        count
      end

      def uploader_path(uploader)
        return unless uploader.file.present?

        uploader.file.path
      end

      def finalize_chunk!(io, path, chunk_paths)
        io.close
        sort_file(path, path)
        chunk_paths << path
      end

      def merge_sorted_chunks_dedup(chunk_paths, output_path)
        if chunk_paths.empty?
          File.write(output_path, '')
          return 0
        end

        if chunk_paths.one?
          return deduplicate_sorted_file(chunk_paths.first, output_path)
        end

        readers = chunk_paths.map { |chunk_path| File.open(chunk_path, 'rb') }
        heads = readers.map { |reader| read_head(reader) }
        written = 0
        last_digest = nil

        File.open(output_path, 'wb') do |out|
          loop do
            candidates = heads.each_with_index.select { |head, _| head }
            break if candidates.empty?

            min_digest = candidates.map { |head, _| digest_of(head) }.min
            unless min_digest == last_digest
              line = candidates.find { |head, _| digest_of(head) == min_digest }.first
              out.write(ensure_row_newline(line))
              last_digest = min_digest
              written += 1
            end

            heads.each_with_index do |head, index|
              next unless head
              next unless digest_of(head) == min_digest

              heads[index] = read_head(readers[index])
            end
          end
        end

        written
      ensure
        readers&.each(&:close)
      end

      def deduplicate_sorted_file(input_path, output_path)
        written = 0
        last_digest = nil

        File.open(output_path, 'wb') do |out|
          File.foreach(input_path) do |row|
            digest = digest_of(row.chomp)
            next if digest == last_digest

            out.write(ensure_row_newline(row.chomp))
            last_digest = digest
            written += 1
          end
        end

        written
      end

      def digest_of(row)
        row.split(SEP, 2).first
      end

      def read_head(reader)
        return nil if reader.eof?

        reader.readline.chomp
      rescue EOFError
        nil
      end

      def ensure_row_newline(row)
        row.end_with?("\n") ? row : "#{row}\n"
      end
    end
  end
end
