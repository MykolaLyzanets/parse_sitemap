# frozen_string_literal: true

module Dashboard
  class SiteMapper
    def self.to_dto(site)
      last_scan = site.scans.chronological.first
      last_completed = site.scans.completed.chronological.first

      Dto::Site.new(
        id: site.id,
        name: site.name,
        domain: site.domain,
        sitemap_url: site.sitemap_url,
        notes: site.notes,
        url_count: last_completed&.total_count || 0,
        last_scan_id: last_scan&.id,
        last_scan_at: last_scan&.scanned_at,
        last_added_count: last_scan&.added_count || 0,
        last_removed_count: last_scan&.removed_count || 0
      )
    end
  end
end
