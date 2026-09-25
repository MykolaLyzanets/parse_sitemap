# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scans::SnapshotFile do
  def collect_sorted_rows(path)
    rows = []
    File.foreach(path) { |row| rows << row.chomp }
    rows
  end

  describe '.write_sorted_from_normalized_urls' do
    it 'sorts rows by digest and deduplicates across chunks' do
      path = Tempfile.new(['sorted', '.tsv']).path
      urls = %w[
        https://chunk.test/z-last
        https://chunk.test/a-first
        https://chunk.test/a-first
        https://chunk.test/m-mid
      ]

      unique_count = described_class.write_sorted_from_normalized_urls(path, chunk_rows: 2) do |emit|
        urls.each { |url| emit.call(url) }
      end

      expect(unique_count).to eq(3)
      digests = collect_sorted_rows(path).map { |row| row.split("\t", 2).first }
      expect(digests).to eq(digests.sort)
      expect(digests.uniq.size).to eq(3)
    end

    it 'returns zero for an empty stream' do
      path = Tempfile.new(['sorted', '.tsv']).path

      unique_count = described_class.write_sorted_from_normalized_urls(path) { |_| }

      expect(unique_count).to eq(0)
      expect(File.read(path)).to eq('')
    end
  end
end
