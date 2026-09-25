# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SiteUrls::Normalizer do
  describe '.normalize' do
    it 'strips trailing slash from paths' do
      expect(described_class.normalize('https://Example.com/page/')).to eq('https://example.com/page')
    end

    it 'keeps root path as /' do
      expect(described_class.normalize('https://example.com/')).to eq('https://example.com/')
    end
  end

  describe '.digest' do
    it 'normalizes before hashing' do
      raw = 'https://example.com/page/'
      canonical = 'https://example.com/page'

      expect(described_class.digest(raw)).to eq(described_class.digest(canonical))
      expect(described_class.digest(raw)).to eq(Digest::SHA256.hexdigest(canonical))
    end
  end
end
