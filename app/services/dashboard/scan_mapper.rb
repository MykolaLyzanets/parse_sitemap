# frozen_string_literal: true

module Dashboard
  class ScanMapper
    def self.to_dto(scan)
      Dto::Scan.new(
        id: scan.id,
        site_id: scan.site_id,
        scanned_at: scan.scanned_at,
        status: scan.status,
        total_count: scan.total_count,
        added_count: scan.added_count,
        removed_count: scan.removed_count,
        unchanged_count: scan.unchanged_count,
        added_urls: [],
        removed_urls: [],
        unchanged_urls: []
      )
    end
  end
end
