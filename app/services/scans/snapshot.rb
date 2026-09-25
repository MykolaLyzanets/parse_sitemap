# frozen_string_literal: true

module Scans
  class Snapshot
    def self.previous_snapshot_path(site)
      SnapshotFile.uploader_path(site.snapshot)
    end

    def self.previous_present?(site)
      previous_snapshot_path(site).present?
    end
  end
end
