# frozen_string_literal: true

module Dashboard
  module Dto
    Scan = Data.define(
      :id, :site_id, :scanned_at, :status,
      :total_count, :added_count, :removed_count, :unchanged_count,
      :added_urls, :removed_urls, :unchanged_urls
    ) do
      def to_param
        id.to_s
      end
    end

    Site = Data.define(
      :id, :name, :domain, :sitemap_url, :notes,
      :url_count, :last_scan_id, :last_scan_at,
      :last_added_count, :last_removed_count
    ) do
      def to_param
        id.to_s
      end
    end

    RemovedUrlRow = Data.define(:url, :first_detected_at, :scan_id, :scan_at)

    UrlPage = Data.define(:urls, :page, :per_page, :total_count, :total_pages, :change_type)

    RemovedUrlPage = Data.define(:rows, :page, :per_page, :total_count, :total_pages)
  end
end
