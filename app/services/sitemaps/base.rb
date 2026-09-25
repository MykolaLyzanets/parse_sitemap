# frozen_string_literal: true

module Sitemaps
  class Base
    def initialize(site)
      @site = site
    end

    def each_url
      raise NotImplementedError, "#{self.class} must implement #each_url"
    end

    protected

    attr_reader :site
  end
end
