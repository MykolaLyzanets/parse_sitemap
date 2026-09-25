# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scans::Service do
  let(:site) { Site.create!(domain: 'scan-test.local', name: 'Scan Test', sitemap_url: 'https://scan-test.local/sitemap.xml') }

  def stub_parser(urls)
    Sitemaps::Testing::StubParser.new(site, urls: urls)
  end

  describe '.call' do
    it 'creates a completed scan with snapshot files on first run' do
      scan = described_class.call(
        site: site,
        parser: stub_parser(['https://scan-test.local/a', 'https://scan-test.local/b'])
      )

      expect(scan).to be_completed
      expect(scan.total_count).to eq(2)
      expect(scan.added_count).to eq(2)
      expect(scan.removed_count).to eq(0)
      expect(scan.unchanged_count).to eq(0)
      expect(scan.added_urls_snapshot.file).to be_present
      site.reload
      expect(site.snapshot.file).to be_present
    end

    it 'computes diff against the previous snapshot' do
      described_class.call(site: site, parser: stub_parser(['https://scan-test.local/a', 'https://scan-test.local/b']))
      site.reload

      second_scan = described_class.call(
        site: site,
        parser: stub_parser(['https://scan-test.local/a', 'https://scan-test.local/c'])
      )

      expect(second_scan).to be_completed
      expect(second_scan.added_count).to eq(1)
      expect(second_scan.removed_count).to eq(1)
      expect(second_scan.unchanged_count).to eq(1)
    end

    it 'fails instead of wiping snapshot when parser returns empty' do
      described_class.call(site: site, parser: stub_parser(['https://scan-test.local/a']))
      site.reload
      previous_snapshot = site.snapshot.identifier

      scan = described_class.call(site: site, parser: stub_parser([]))

      expect(scan).to be_failed
      site.reload
      expect(site.snapshot.identifier).to eq(previous_snapshot)
    end

    it 'allows an empty first scan when there is no previous snapshot' do
      scan = described_class.call(site: site, parser: stub_parser([]))

      expect(scan).to be_completed
      expect(scan.total_count).to eq(0)
    end

    it 'does not replace site snapshot when persistence fails' do
      described_class.call(site: site, parser: stub_parser(['https://scan-test.local/a']))
      site.reload
      previous_snapshot = site.snapshot.identifier

      allow(Scans::Persistence).to receive(:complete_scan!).and_raise(ActiveRecord::RecordInvalid.new(site))

      scan = described_class.call(site: site, parser: stub_parser(['https://scan-test.local/b']))

      expect(scan).to be_failed
      site.reload
      expect(site.snapshot.identifier).to eq(previous_snapshot)
    end

    it 'marks scan as failed when parser raises' do
      parser = instance_double(Sitemaps::Base)
      allow(parser).to receive(:each_url).and_raise(StandardError, 'network down')

      scan = described_class.call(site: site, parser: parser)

      expect(scan).to be_failed
      expect(scan.error_message).to eq('network down')
    end
  end
end
