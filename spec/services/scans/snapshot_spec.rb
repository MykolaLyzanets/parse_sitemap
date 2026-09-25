# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scans::Snapshot do
  let(:site) { Site.create!(domain: 'snapshot.test', name: 'Snapshot', sitemap_url: 'https://snapshot.test/sitemap.xml') }

  it 'detects previous snapshot file on site' do
    expect(described_class.previous_present?(site)).to be(false)

    file = Tempfile.new(['snapshot', '.tsv'])
    Scans::SnapshotFile.write_unsorted(file.path, ['https://snapshot.test/a'])
    Scans::SnapshotFile.sort_file(file.path, file.path)
    gz = Tempfile.new(['snapshot', '.gz'])
    Scans::SnapshotFile.gzip_file(file.path, gz.path)
    site.snapshot = File.open(gz.path)
    site.save!

    expect(described_class.previous_present?(site)).to be(true)
    expect(described_class.previous_snapshot_path(site)).to be_present
  end
end
