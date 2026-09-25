# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scans::StreamingDiff do
  let(:site) { Site.create!(domain: 'diff.test', name: 'Diff', sitemap_url: 'https://diff.test/sitemap.xml') }

  def attach_snapshot(site, urls)
    file = Tempfile.new(['snapshot', '.tsv'])
    Scans::SnapshotFile.write_unsorted(file.path, urls)
    Scans::SnapshotFile.sort_file(file.path, file.path)
    gz = Tempfile.new(['snapshot', '.gz'])
    Scans::SnapshotFile.gzip_file(file.path, gz.path)
    site.snapshot = File.open(gz.path)
    site.save!
  end

  def run_diff(site, urls)
    described_class.call(site: site) do |emit|
      urls.each { |url| emit.call(url) }
    end
  end

  it 'marks all URLs as added on first scan' do
    result = run_diff(site, ['https://diff.test/a', 'https://diff.test/b'])

    expect(result.added_count).to eq(2)
    expect(result.removed_count).to eq(0)
    expect(result.unchanged_count).to eq(0)
    expect(result.total_count).to eq(2)
    expect(Scans::SnapshotFile.count_entries(result.added_snapshot_gz_path)).to eq(2)
    expect(Scans::SnapshotFile.count_entries(result.removed_snapshot_gz_path)).to eq(0)
  end

  it 'computes added, removed and unchanged against previous snapshot' do
    attach_snapshot(site, ['https://diff.test/keep', 'https://diff.test/gone'])

    result = run_diff(site, ['https://diff.test/keep', 'https://diff.test/new'])

    expect(result.added_count).to eq(1)
    expect(result.removed_count).to eq(1)
    expect(result.unchanged_count).to eq(1)
    expect(result.total_count).to eq(2)

    added_urls = []
    Scans::SnapshotFile.each_entry(result.added_snapshot_gz_path) { |_d, url| added_urls << url }
    removed_urls = []
    Scans::SnapshotFile.each_entry(result.removed_snapshot_gz_path) { |_d, url| removed_urls << url }

    expect(added_urls).to eq(['https://diff.test/new'])
    expect(removed_urls).to eq(['https://diff.test/gone'])
  end

  it 'deduplicates duplicate URLs before diff' do
    result = run_diff(site, ['https://diff.test/a', 'https://diff.test/a'])

    expect(result.total_count).to eq(1)
    expect(result.added_count).to eq(1)
  end
end
