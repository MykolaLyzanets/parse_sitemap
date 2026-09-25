# frozen_string_literal: true

require 'digest'

module SiteUrls
  class Normalizer
    def self.normalize(raw_url)
      url = raw_url.to_s.strip
      return url if url.blank?

      uri = URI.parse(url)
      raise URI::InvalidURIError, 'relative URL' unless uri.absolute?

      scheme = uri.scheme&.downcase
      host = uri.host&.downcase
      path = uri.path.presence || '/'
      path = path.chomp('/') if path != '/'

      port =
        if uri.port && !default_port?(scheme, uri.port)
          ":#{uri.port}"
        else
          ''
        end

      query = uri.query ? "?#{uri.query}" : ''

      "#{scheme}://#{host}#{port}#{path}#{query}"
    rescue URI::InvalidURIError
      raw_url.to_s.strip
    end

    def self.digest(raw_url)
      Digest::SHA256.hexdigest(normalize(raw_url))
    end

    def self.default_port?(scheme, port)
      (scheme == 'http' && port == 80) || (scheme == 'https' && port == 443)
    end
  end
end
