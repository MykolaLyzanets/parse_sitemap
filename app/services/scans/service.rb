# frozen_string_literal: true

module Scans
  class Service
    def self.call(site:, parser: nil)
      new(site: site, parser: parser).call
    end

    def initialize(site:, parser: nil)
      @site = site
      @parser = parser || Sitemaps::Registry.for(site)
    end

    def call
      scan = Persistence.start_scan!(site)
      Log.info(site: site, scan_id: scan.id, message: "Старт (#{parser.class.name})")

      begin
        Log.info(site: site, scan_id: scan.id, message: 'Завантаження sitemap…')
        normalized_count = 0

        diff_result = StreamingDiff.call(site: site, scan_id: scan.id) do |emit|
          parser.each_url do |raw_url|
            normalized = SiteUrls::Normalizer.normalize(raw_url)
            next if normalized.blank?

            normalized_count += 1
            emit.call(normalized)
          end
        end

        Log.info(
          site: site,
          scan_id: scan.id,
          message: "Отримано URL: #{normalized_count} після normalize (унікальних у snapshot: #{diff_result.total_count})"
        )

        guard_empty_sitemap!(diff_result.total_count)
        Log.info(
          site: site,
          scan_id: scan.id,
          message: "Diff: +#{diff_result.added_count} −#{diff_result.removed_count} =#{diff_result.unchanged_count}"
        )

        Log.info(site: site, scan_id: scan.id, message: 'Збереження snapshot-файлів…')
        finished_at = Time.current
        ActiveRecord::Base.transaction do
          Persistence.complete_scan!(scan, site, diff_result, finished_at: finished_at)
        end

        scan.reload
        site.reload
        Log.info(site: site, scan_id: scan.id, message: "Завершено (status=#{scan.status}, total=#{scan.total_count})")
        scan
      rescue StandardError => e
        Persistence.fail_scan!(scan, e.message)
        scan.reload
        Log.error(
          site: site,
          scan_id: scan.id,
          message: "Помилка: #{e.class} — #{e.message}",
          exception: e
        )
        scan
      end
    end

    private

    attr_reader :site, :parser

    def guard_empty_sitemap!(unique_url_count)
      return if unique_url_count.positive?
      return unless Snapshot.previous_present?(site)

      raise EmptySitemapError
    end
  end
end
