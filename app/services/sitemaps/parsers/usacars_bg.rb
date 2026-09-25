# frozen_string_literal: true

require 'rexml/document'
require 'rexml/xpath'

module Sitemaps
  module Parsers
    class UsacarsBg < GenericParser
      VEHICLE_SITEMAP_PATH_PATTERNS = [
        %r{/sitemap/vehicles/active-\d+\.xml\z}i,
        %r{/sitemap/vehicles/hot-\d+\.xml\z}i,
        %r{/sitemap/vehicles/resale-\d+\.xml\z}i,
        %r{/sitemap/archive\.xml\z}i
      ].freeze

      def each_url
        return enum_for(:each_url) unless block_given?

        selected_sitemaps = vehicle_sitemap_urls
        log("Індекс: обрано #{selected_sitemaps.size} vehicle sitemap-ів")

        selected_sitemaps.each_with_index do |sitemap_url, index|
          count = 0
          stream_document_urls(sitemap_url) do |url|
            count += 1
            yield url
          end
          log("sitemap #{index + 1}/#{selected_sitemaps.size}: #{sitemap_url} → #{count} URL")
        end

        log("HTTP/XML парсинг завершено: #{selected_sitemaps.size} sitemap-файлів")
      end

      private

      def log(message)
        Rails.logger.info("[Scan] site=#{site.domain} #{message}")
      end

      def vehicle_sitemap_urls
        log('Завантаження головного sitemap.xml…')
        document = REXML::Document.new(http_get(site.sitemap_url))
        extract_all_locs(document).select { |loc| vehicle_sitemap_path?(loc) }
      end

      def extract_all_locs(document)
        locs = []
        REXML::XPath.each(document, '//*[local-name()="loc"]') do |element|
          locs << element.text.strip if element.text.present?
        end
        locs
      end

      def vehicle_sitemap_path?(url)
        path = URI.parse(url).path
        VEHICLE_SITEMAP_PATH_PATTERNS.any? { |pattern| path.match?(pattern) }
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
