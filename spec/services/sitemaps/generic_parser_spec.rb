# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sitemaps::GenericParser do
  let(:site) { Site.new(domain: 'xml.test', sitemap_url: 'https://xml.test/sitemap.xml') }

  it 'extracts page URLs from a urlset document' do
    parser = described_class.new(site)
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url><loc>https://xml.test/one</loc></url>
        <url><loc>https://xml.test/two</loc></url>
      </urlset>
    XML

    allow(Sitemaps::HttpClient).to receive(:get).with(site.sitemap_url).and_return(xml)

    expect(parser.each_url.to_a).to contain_exactly('https://xml.test/one', 'https://xml.test/two')
  end

  it 'follows sitemap index documents' do
    parser = described_class.new(site)
    index_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <sitemap><loc>https://xml.test/sitemap-1.xml</loc></sitemap>
      </sitemapindex>
    XML
    child_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url><loc>https://xml.test/child</loc></url>
      </urlset>
    XML

    allow(Sitemaps::HttpClient).to receive(:get).with(site.sitemap_url).and_return(index_xml)
    allow(Sitemaps::HttpClient).to receive(:get).with('https://xml.test/sitemap-1.xml').and_return(child_xml)

    expect(parser.each_url.to_a).to eq(['https://xml.test/child'])
  end

  it 'deduplicates URLs across nested sitemaps' do
    parser = described_class.new(site)
    index_xml = <<~XML
      <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <sitemap><loc>https://xml.test/a.xml</loc></sitemap>
        <sitemap><loc>https://xml.test/b.xml</loc></sitemap>
      </sitemapindex>
    XML
    child_a = <<~XML
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url><loc>https://xml.test/shared</loc></url>
      </urlset>
    XML
    child_b = <<~XML
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url><loc>https://xml.test/shared</loc></url>
        <url><loc>https://xml.test/unique</loc></url>
      </urlset>
    XML

    allow(Sitemaps::HttpClient).to receive(:get).with(site.sitemap_url).and_return(index_xml)
    allow(Sitemaps::HttpClient).to receive(:get).with('https://xml.test/a.xml').and_return(child_a)
    allow(Sitemaps::HttpClient).to receive(:get).with('https://xml.test/b.xml').and_return(child_b)

    urls = parser.each_url.to_a
    expect(urls).to contain_exactly(
      'https://xml.test/shared',
      'https://xml.test/shared',
      'https://xml.test/unique'
    )
  end

  it 'does not recurse into the same sitemap URL twice' do
    parser = described_class.new(site)
    cyclic_index = <<~XML
      <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <sitemap><loc>https://xml.test/sitemap.xml</loc></sitemap>
      </sitemapindex>
    XML

    allow(Sitemaps::HttpClient).to receive(:get).with(site.sitemap_url).and_return(cyclic_index)

    expect(parser.each_url.to_a).to eq([])
  end
end
