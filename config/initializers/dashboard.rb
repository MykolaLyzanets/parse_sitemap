# frozen_string_literal: true

Rails.application.config.x.dashboard = ActiveSupport::OrderedOptions.new
Rails.application.config.x.dashboard.urls_per_page = ENV.fetch('DASHBOARD_URLS_PER_PAGE', 100).to_i.clamp(10, 500)
