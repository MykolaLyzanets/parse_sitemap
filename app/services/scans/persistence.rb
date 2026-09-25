# frozen_string_literal: true

module Scans
  class Persistence
    def self.start_scan!(site)
      site.scans.create!(
        status: :running,
        started_at: Time.current
      )
    end

    def self.complete_scan!(scan, site, diff_result, finished_at: Time.current)
      scan.added_urls_snapshot = File.open(diff_result.added_snapshot_gz_path)
      scan.removed_urls_snapshot = File.open(diff_result.removed_snapshot_gz_path)
      scan.update!(
        status: :completed,
        finished_at: finished_at,
        total_count: diff_result.total_count,
        added_count: diff_result.added_count,
        removed_count: diff_result.removed_count,
        unchanged_count: diff_result.unchanged_count,
        error_message: nil
      )

      site.snapshot = File.open(diff_result.current_snapshot_gz_path)
      site.save!
    end

    def self.fail_scan!(scan, message, finished_at: Time.current)
      scan.update!(
        status: :failed,
        finished_at: finished_at,
        error_message: message.to_s.truncate(10_000)
      )
    end
  end
end
