# frozen_string_literal: true

module Dashboard
  class ScansRepository
    CHANGE_TYPES = %w[added removed unchanged].freeze

    def self.for_site(site_id)
      Scan.where(site_id: site_id).chronological.map { |scan| ScanMapper.to_dto(scan) }
    end

    def self.find(site_id, scan_id)
      scan = Scan.find_by(site_id: site_id, id: scan_id)
      return unless scan

      ScanMapper.to_dto(scan)
    end

    def self.urls_page(site_id, scan_id, change_type:, page:)
      change_type = CHANGE_TYPES.include?(change_type.to_s) ? change_type.to_s : 'added'
      page = Pagination.normalize_page(page)
      per_page = Pagination.per_page

      scan = Scan.find_by(site_id: site_id, id: scan_id)
      return unless scan

      total_count = scan.public_send(:"#{change_type}_count")
      urls = urls_from_snapshot(scan, change_type, page: page, per_page: per_page)

      Dto::UrlPage.new(
        urls: urls,
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: Pagination.total_pages(total_count),
        change_type: change_type
      )
    end

    def self.urls_from_snapshot(scan, change_type, page:, per_page:)
      return [] if change_type == 'unchanged'

      path = case change_type
             when 'added' then Scans::SnapshotFile.uploader_path(scan.added_urls_snapshot)
             when 'removed' then Scans::SnapshotFile.uploader_path(scan.removed_urls_snapshot)
             end
      return [] unless path

      Scans::SnapshotFile.each_url(path, page: page, per_page: per_page)
    end
  end
end
