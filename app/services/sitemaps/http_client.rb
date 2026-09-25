# frozen_string_literal: true

require 'faraday'

module Sitemaps
  class HttpClient
    USER_AGENT =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' \
      'Chrome/122.0.0.0 Safari/537.36 SitemapMonitor/1.0'
    MAX_RETRIES = 5
    THROTTLE_SECONDS_MIN = 0.5
    THROTTLE_SECONDS_MAX = 1.5
    INITIAL_BACKOFF_SECONDS = 1.0
    JITTER_RATIO = 0.25
    OPEN_TIMEOUT_SECONDS = 15
    REQUEST_TIMEOUT_SECONDS = 60

    RETRYABLE_EXCEPTIONS = [
      Faraday::ConnectionFailed,
      Faraday::TimeoutError,
      Net::OpenTimeout
    ].freeze

    class RequestError < StandardError; end

    @domain_locks = Hash.new { |hash, key| hash[key] = Mutex.new }
    @last_request_at = {}
    @last_request_at_mutex = Mutex.new

    class << self
      attr_accessor :sleep_callback, :random_fraction_callback

      def get(url)
        new.get(url)
      end

      def domain_locks
        @domain_locks
      end

      def last_request_at
        @last_request_at
      end

      def last_request_at_mutex
        @last_request_at_mutex
      end

      def reset_throttle_state!
        last_request_at_mutex.synchronize { @last_request_at.clear }
      end

      def random_fraction
        if random_fraction_callback
          random_fraction_callback.call
        else
          rand
        end
      end

      def sleep(seconds)
        if sleep_callback
          sleep_callback.call(seconds)
        else
          Kernel.sleep(seconds)
        end
      end
    end

    def get(url)
      domain = domain_for(url)

      self.class.domain_locks[domain].synchronize do
        throttle!(domain)
        perform_with_retry(url, domain).tap { record_request!(domain) }
      end
    end

    private

    def domain_for(url)
      URI.parse(url).host or raise ArgumentError, "invalid URL: #{url}"
    end

    def throttle!(domain)
      wait = self.class.last_request_at_mutex.synchronize do
        last_at = self.class.last_request_at[domain]
        next 0 unless last_at

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - last_at
        remaining = throttle_pause_duration - elapsed
        remaining.positive? ? remaining : 0
      end

      self.class.sleep(wait) if wait.positive?
    end

    def throttle_pause_duration
      span = THROTTLE_SECONDS_MAX - THROTTLE_SECONDS_MIN
      THROTTLE_SECONDS_MIN + (span * self.class.random_fraction)
    end

    def record_request!(domain)
      self.class.last_request_at_mutex.synchronize do
        self.class.last_request_at[domain] = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end

    def perform_with_retry(url, domain)
      attempts = 0

      loop do
        begin
          response = connection.get(url)
          return response.body if response.success?

          unless retryable_status?(response.status) && attempts < MAX_RETRIES
            raise RequestError, "HTTP #{response.status} for #{url}"
          end

          attempts += 1
          delay = retry_delay(response, attempts)
          log_retry(domain: domain, url: url, reason: "HTTP #{response.status}", attempt: attempts, delay: delay)
          self.class.sleep(delay)
        rescue *RETRYABLE_EXCEPTIONS => e
          attempts += 1
          unless attempts <= MAX_RETRIES
            raise RequestError, "#{e.class}: #{e.message} for #{url}"
          end

          delay = retry_delay_for_exception(attempts)
          log_retry(domain: domain, url: url, reason: e.class.name, attempt: attempts, delay: delay)
          self.class.sleep(delay)
        end
      end
    end

    def retryable_status?(status)
      [403, 408, 429].include?(status)
    end

    def retry_delay(response, attempt)
      if response.status == 429
        header = response.headers['Retry-After']
        return parse_retry_after(header) if header.present?
      end

      backoff_with_jitter(attempt)
    end

    def retry_delay_for_exception(attempt)
      backoff_with_jitter(attempt)
    end

    def backoff_with_jitter(attempt)
      base = INITIAL_BACKOFF_SECONDS * (2**(attempt - 1))
      jitter = base * JITTER_RATIO * self.class.random_fraction
      base + jitter
    end

    def parse_retry_after(value)
      seconds = Integer(value)
      seconds.positive? ? seconds : INITIAL_BACKOFF_SECONDS
    rescue ArgumentError
      wait = Time.httpdate(value) - Time.now
      wait.positive? ? wait : INITIAL_BACKOFF_SECONDS
    end

    def log_retry(domain:, url:, reason:, attempt:, delay:)
      Rails.logger.info(
        "[Sitemap HTTP] host=#{domain} url=#{url} retry=#{attempt}/#{MAX_RETRIES} " \
        "reason=#{reason} delay=#{delay.round(2)}s"
      )
    end

    def connection
      @connection ||= Faraday.new do |faraday|
        faraday.headers['User-Agent'] = USER_AGENT
        faraday.options.open_timeout = OPEN_TIMEOUT_SECONDS
        faraday.options.timeout = REQUEST_TIMEOUT_SECONDS
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
