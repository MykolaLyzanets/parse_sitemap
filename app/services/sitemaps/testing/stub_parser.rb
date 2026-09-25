# frozen_string_literal: true

module Sitemaps
  module Testing
    class StubParser < Base
      def initialize(site, urls:)
        super(site)
        @urls = urls
      end

      def each_url
        return enum_for(:each_url) unless block_given?

        @urls.each { |url| yield url }
      end
    end
  end
end
