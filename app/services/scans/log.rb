# frozen_string_literal: true

module Scans
  module Log
    TAG = '[Scan]'

    module_function

    def info(site:, scan_id: nil, message:)
      Rails.logger.info("#{TAG} #{context(site: site, scan_id: scan_id)} #{message}")
    end

    def warn(site:, scan_id: nil, message:)
      Rails.logger.warn("#{TAG} #{context(site: site, scan_id: scan_id)} #{message}")
    end

    def error(site:, scan_id: nil, message:, exception: nil)
      Rails.logger.error("#{TAG} #{context(site: site, scan_id: scan_id)} #{message}")
      Rails.logger.error(exception.full_message) if exception
    end

    def context(site:, scan_id:)
      parts = ["site=#{site.domain}"]
      parts << "scan_id=#{scan_id}" if scan_id
      parts.join(' ')
    end
  end
end
