# frozen_string_literal: true

module Scans
  class EmptySitemapError < StandardError
    def initialize
      super('Sitemap parser returned no URLs while a previous completed scan had URLs')
    end
  end
end
