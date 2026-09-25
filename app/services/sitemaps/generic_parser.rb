# frozen_string_literal: true

module Sitemaps
  class GenericParser < Base
    def each_url
      return enum_for(:each_url) unless block_given?

      raise ArgumentError, 'sitemap_url is blank' if site.sitemap_url.blank?

      stream_document_urls(site.sitemap_url, visited: Set.new) { |url| yield url }
    end

    private

    def stream_document_urls(sitemap_url, visited: Set.new)
      return if visited.include?(sitemap_url)

      visited << sitemap_url
      body = http_get(sitemap_url)

      nested_sitemaps = []
      XmlLocStreamer.each_loc(body) do |parent, loc|
        case parent
        when 'url'
          yield loc
        when 'sitemap'
          nested_sitemaps << loc
        end
      end

      nested_sitemaps.each do |nested_url|
        stream_document_urls(nested_url, visited: visited) { |url| yield url }
      end
    end

    def http_get(url)
      HttpClient.get(url)
    end
  end
end
