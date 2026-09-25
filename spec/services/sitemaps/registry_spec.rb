# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sitemaps::Registry do
  it 'returns a site-specific parser for a known domain' do
    site = Site.new(domain: 'example.com', sitemap_url: 'https://example.com/sitemap.xml')
    parser = described_class.for(site)

    expect(parser).to be_a(Sitemaps::Parsers::ExampleCom)
  end

  it 'returns UsacarsBg for usacars.bg' do
    site = Site.new(domain: 'usacars.bg', sitemap_url: 'https://usacars.bg/sitemap.xml')
    parser = described_class.for(site)

    expect(parser).to be_a(Sitemaps::Parsers::UsacarsBg)
  end

  it 'falls back to GenericParser for unknown domains' do
    site = Site.new(domain: 'unknown.example', sitemap_url: 'https://unknown.example/sitemap.xml')
    parser = described_class.for(site)

    expect(parser).to be_a(Sitemaps::GenericParser)
  end
end
