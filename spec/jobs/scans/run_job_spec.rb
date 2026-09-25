# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scans::RunJob, type: :job do
  let(:site) { Site.create!(domain: 'job.test', name: 'Job', sitemap_url: 'https://job.test/sitemap.xml') }

  it 'runs Scans::Service for the site' do
    parser = Sitemaps::Testing::StubParser.new(site, urls: ['https://job.test/a'])
    allow(Sitemaps::Registry).to receive(:for).with(site).and_return(parser)

    expect do
      described_class.perform_now(site.id)
    end.to change { site.scans.completed.count }.by(1)
  end

  it 'skips when a scan is already running' do
    site.scans.create!(status: :running, started_at: Time.current)
    allow(Scans::Service).to receive(:call)

    described_class.perform_now(site.id)

    expect(Scans::Service).not_to have_received(:call)
  end
end
