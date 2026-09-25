# frozen_string_literal: true

module Scans
  class RunJob < ApplicationJob
    queue_as :default

    def perform(site_id)
      site = Site.find(site_id)

      if site.scans.running.exists?
        Scans::Log.warn(site: site, message: 'Job пропущено — сканування вже виконується')
        return
      end

      Scans::Log.info(site: site, message: 'Job стартує Scans::Service')
      Scans::Service.call(site: site)
      Scans::Log.info(site: site, message: 'Job завершено')
    end
  end
end
