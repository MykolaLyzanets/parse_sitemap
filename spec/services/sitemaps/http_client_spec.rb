# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sitemaps::HttpClient do
  let(:connection) { instance_double(Faraday::Connection) }
  let(:url) { 'https://xml.test/sitemap.xml' }
  let(:sleeps) { [] }

  def build_response(status:, body: '', headers: {})
    instance_double(
      Faraday::Response,
      success?: status == 200,
      status: status,
      body: body,
      headers: headers
    )
  end

  before do
    described_class.reset_throttle_state!
    described_class.sleep_callback = ->(seconds) { sleeps << seconds }
    described_class.random_fraction_callback = -> { 0 }
    allow_any_instance_of(described_class).to receive(:connection).and_return(connection)
  end

  after do
    described_class.sleep_callback = nil
    described_class.random_fraction_callback = nil
  end

  it 'returns the response body on a normal request' do
    allow(connection).to receive(:get).with(url).and_return(build_response(status: 200, body: '<xml/>'))

    expect(described_class.get(url)).to eq('<xml/>')
    expect(connection).to have_received(:get).with(url).once
  end

  it 'sends a stable User-Agent header' do
    captured_headers = nil
    allow(Faraday).to receive(:new).and_wrap_original do |method, *args, &block|
      method.call(*args) do |faraday|
        captured_headers = faraday.headers
        block&.call(faraday)
      end
    end

    client = described_class.new
    allow(client).to receive(:connection).and_call_original
    allow(client.connection).to receive(:get).and_return(build_response(status: 200, body: 'ok'))

    client.get(url)

    expect(captured_headers['User-Agent']).to eq(described_class::USER_AGENT)
  end

  it 'waits between requests to the same domain' do
    allow(connection).to receive(:get).with(url).and_return(build_response(status: 200, body: 'ok'))

    described_class.get(url)
    sleeps.clear
    described_class.get(url)

    expect(sleeps.size).to eq(1)
    expect(sleeps.first).to be_within(0.05).of(described_class::THROTTLE_SECONDS_MIN)
  end

  it 'allows only one in-flight request per domain' do
    in_flight = 0
    max_in_flight = 0
    guard = Mutex.new

    allow(connection).to receive(:get) do
      guard.synchronize do
        in_flight += 1
        max_in_flight = in_flight if in_flight > max_in_flight
      end
      described_class.sleep(0.05)
      guard.synchronize { in_flight -= 1 }
      build_response(status: 200, body: 'ok')
    end

    threads = Array.new(2) { Thread.new { described_class.get(url) } }
    threads.each(&:join)

    expect(max_in_flight).to eq(1)
  end

  it 'retries on HTTP 429 and succeeds' do
    allow(connection).to receive(:get).with(url).and_return(
      build_response(status: 429),
      build_response(status: 200, body: 'ok')
    )

    expect(described_class.get(url)).to eq('ok')
    expect(connection).to have_received(:get).with(url).twice
    expect(sleeps).to eq([described_class::INITIAL_BACKOFF_SECONDS])
  end

  it 'retries on HTTP 403 and succeeds' do
    allow(connection).to receive(:get).with(url).and_return(
      build_response(status: 403),
      build_response(status: 200, body: 'ok')
    )

    expect(described_class.get(url)).to eq('ok')
    expect(connection).to have_received(:get).with(url).twice
    expect(sleeps).not_to be_empty
  end

  it 'uses Retry-After when present on HTTP 429' do
    allow(connection).to receive(:get).with(url).and_return(
      build_response(status: 429, headers: { 'Retry-After' => '4' }),
      build_response(status: 200, body: 'ok')
    )

    described_class.get(url)

    expect(sleeps.first).to eq(4)
  end

  it 'retries on Net::OpenTimeout with backoff and succeeds' do
    calls = 0
    allow(connection).to receive(:get) do
      calls += 1
      raise Net::OpenTimeout, 'execution expired' if calls == 1

      build_response(status: 200, body: 'ok')
    end

    expect(described_class.get(url)).to eq('ok')
    expect(calls).to eq(2)
    expect(sleeps).to eq([described_class::INITIAL_BACKOFF_SECONDS])
  end

  it 'raises after max retries are exhausted for HTTP 429' do
    allow(connection).to receive(:get).with(url).and_return(build_response(status: 429))

    expect { described_class.get(url) }.to raise_error(
      described_class::RequestError,
      "HTTP 429 for #{url}"
    )
    expect(connection).to have_received(:get).with(url).exactly(described_class::MAX_RETRIES + 1).times
  end

  it 'raises after max retries are exhausted for Net::OpenTimeout' do
    allow(connection).to receive(:get).with(url).and_raise(Net::OpenTimeout, 'execution expired')

    expect { described_class.get(url) }.to raise_error(
      described_class::RequestError,
      /OpenTimeout: execution expired for #{url}/
    )
    expect(connection).to have_received(:get).with(url).exactly(described_class::MAX_RETRIES + 1).times
  end

  it 'does not retry permanent client errors' do
    allow(connection).to receive(:get).with(url).and_return(build_response(status: 404))

    expect { described_class.get(url) }.to raise_error(described_class::RequestError, "HTTP 404 for #{url}")
    expect(connection).to have_received(:get).with(url).once
    expect(sleeps).to be_empty
  end
end
