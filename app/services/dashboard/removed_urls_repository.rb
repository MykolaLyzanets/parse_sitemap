# frozen_string_literal: true

module Dashboard
  class RemovedUrlsRepository
    def self.for_site(site_id, page: 1)
      page = Pagination.normalize_page(page)
      per_page = Pagination.per_page

      rows = build_rows(site_id)
      total_count = rows.size
      offset = Pagination.offset_for(page)
      page_rows = rows.slice(offset, per_page) || []

      Dto::RemovedUrlPage.new(
        rows: page_rows,
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: Pagination.total_pages(total_count)
      )
    end

    def self.build_rows(site_id)
      grouped = {}

      Scan.completed.where(site_id: site_id).where('removed_count > 0').find_each do |scan|
        path = Scans::SnapshotFile.uploader_path(scan.removed_urls_snapshot)
        next unless path

        Scans::SnapshotFile.each_entry(path) do |_digest, url|
          grouped[url] ||= {
            url: url,
            first_detected_at: scan.finished_at,
            scan_id: scan.id,
            scan_at: scan.finished_at
          }
          if scan.finished_at > grouped[url][:scan_at]
            grouped[url][:scan_id] = scan.id
            grouped[url][:scan_at] = scan.finished_at
          end
          if scan.finished_at < grouped[url][:first_detected_at]
            grouped[url][:first_detected_at] = scan.finished_at
          end
        end
      end

      grouped.values
             .map { |row| Dto::RemovedUrlRow.new(**row) }
             .sort_by(&:first_detected_at)
             .reverse
    end
  end
end
