# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sitemaps::Parsers::UsacarsBg do
  let(:site) do
    Site.new(
      domain: 'usacars.bg',
      sitemap_url: 'https://usacars.bg/sitemap.xml'
    )
  end
  let(:parser) { described_class.new(site) }

  let(:main_sitemap_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <sitemap><loc>https://usacars.bg/sitemap/pages.xml</loc></sitemap>
        <sitemap><loc>https://usacars.bg/sitemap/brands.xml</loc></sitemap>
        <sitemap><loc>https://usacars.bg/sitemap/vehicles/active-40.xml</loc></sitemap>
        <sitemap><loc>https://usacars.bg/sitemap/vehicles/active-41.xml</loc></sitemap>
        <sitemap><loc>https://usacars.bg/sitemap/vehicles/hot-993.xml</loc></sitemap>
        <sitemap><loc>https://usacars.bg/sitemap/vehicles/hot-994.xml</loc></sitemap>
        <sitemap><loc>https://usacars.bg/sitemap/vehicles/resale-1297.xml</loc></sitemap>
        <sitemap><loc>https://usacars.bg/sitemap/vehicles/resale-1298.xml</loc></sitemap>
        <sitemap><loc>https://usacars.bg/sitemap/archive.xml</loc></sitemap>
      </sitemapindex>
    XML
  end

  def urlset_xml(urls)
    locs = urls.map { |url| "<url><loc>#{url}</loc></url>" }.join
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        #{locs}
      </urlset>
    XML
  end

  def stub_http_responses
    allow(Sitemaps::HttpClient).to receive(:get).with('https://usacars.bg/sitemap.xml').and_return(main_sitemap_xml)
    allow(Sitemaps::HttpClient).to receive(:get).with('https://usacars.bg/sitemap/vehicles/active-40.xml').and_return(
      urlset_xml(['https://usacars.bg/car/active-40-a'])
    )
    allow(Sitemaps::HttpClient).to receive(:get).with('https://usacars.bg/sitemap/vehicles/active-41.xml').and_return(
      urlset_xml(['https://usacars.bg/car/active-41-a'])
    )
    allow(Sitemaps::HttpClient).to receive(:get).with('https://usacars.bg/sitemap/vehicles/hot-993.xml').and_return(
      urlset_xml(['https://usacars.bg/car/hot-993-a'])
    )
    allow(Sitemaps::HttpClient).to receive(:get).with('https://usacars.bg/sitemap/vehicles/hot-994.xml').and_return(
      urlset_xml(['https://usacars.bg/car/hot-994-a'])
    )
    allow(Sitemaps::HttpClient).to receive(:get).with('https://usacars.bg/sitemap/vehicles/resale-1297.xml').and_return(
      urlset_xml(['https://usacars.bg/car/resale-1297-a'])
    )
    allow(Sitemaps::HttpClient).to receive(:get).with('https://usacars.bg/sitemap/vehicles/resale-1298.xml').and_return(
      urlset_xml(['https://usacars.bg/car/resale-1298-a'])
    )
    allow(Sitemaps::HttpClient).to receive(:get).with('https://usacars.bg/sitemap/archive.xml').and_return(
      urlset_xml(
        [
          'https://usacars.bg/car/archive-a',
          'https://usacars.bg/car/active-40-a'
        ]
      )
    )
  end

  before { stub_http_responses }

  it 'is returned from registry for usacars.bg' do
    expect(Sitemaps::Registry.for(site)).to be_a(described_class)
  end

  it 'parses active, hot, resale and archive sitemaps and ignores pages and brands' do
    urls = parser.each_url.to_a.uniq

    expect(urls).to contain_exactly(
      'https://usacars.bg/car/active-40-a',
      'https://usacars.bg/car/active-41-a',
      'https://usacars.bg/car/hot-993-a',
      'https://usacars.bg/car/hot-994-a',
      'https://usacars.bg/car/resale-1297-a',
      'https://usacars.bg/car/resale-1298-a',
      'https://usacars.bg/car/archive-a'
    )
  end

  it 'does not request ignored sitemap files' do
    parser.each_url.to_a

    expect(Sitemaps::HttpClient).not_to have_received(:get).with('https://usacars.bg/sitemap/pages.xml')
    expect(Sitemaps::HttpClient).not_to have_received(:get).with('https://usacars.bg/sitemap/brands.xml')
  end

  it 'requests every matched vehicle sitemap from the index' do
    parser.each_url.to_a

    expect(Sitemaps::HttpClient).to have_received(:get).with('https://usacars.bg/sitemap/vehicles/active-40.xml')
    expect(Sitemaps::HttpClient).to have_received(:get).with('https://usacars.bg/sitemap/vehicles/active-41.xml')
    expect(Sitemaps::HttpClient).to have_received(:get).with('https://usacars.bg/sitemap/vehicles/hot-993.xml')
    expect(Sitemaps::HttpClient).to have_received(:get).with('https://usacars.bg/sitemap/vehicles/hot-994.xml')
    expect(Sitemaps::HttpClient).to have_received(:get).with('https://usacars.bg/sitemap/vehicles/resale-1297.xml')
    expect(Sitemaps::HttpClient).to have_received(:get).with('https://usacars.bg/sitemap/vehicles/resale-1298.xml')
    expect(Sitemaps::HttpClient).to have_received(:get).with('https://usacars.bg/sitemap/archive.xml')
  end

  it 'yields duplicate vehicle URLs across sitemaps; snapshot build deduplicates by digest' do
    expect(parser.each_url.count { |url| url == 'https://usacars.bg/car/active-40-a' }).to eq(2)

    site = Site.create!(
      domain: 'usacars-dedup.bg',
      name: 'Dedup',
      sitemap_url: 'https://usacars.bg/sitemap.xml'
    )
    result = Scans::StreamingDiff.call(site: site) do |emit|
      parser.each_url do |raw|
        emit.call(SiteUrls::Normalizer.normalize(raw))
      end
    end

    expect(result.total_count).to eq(7)
  end
end
