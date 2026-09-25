# frozen_string_literal: true

module Sitemaps
  class Registry
    PARSERS_BY_DOMAIN = {
      'example.com' => Parsers::ExampleCom,
      'shop.ua' => Parsers::ShopUa,
      'startup.dev' => Parsers::StartupDev,
      'usacars.bg' => Parsers::UsacarsBg
    }.freeze

    def self.for(site)
      parser_class = PARSERS_BY_DOMAIN.fetch(site.domain, GenericParser)
      parser_class.new(site)
    end
  end
end
