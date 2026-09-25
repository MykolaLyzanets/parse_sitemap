# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-cron'

redis_url = ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0')

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  config.on(:startup) do
    schedule_file = Rails.root.join('config/sidekiq_cron.yml')
    if schedule_file.exist?
      Sidekiq::Cron::Job.load_from_hash!(YAML.load_file(schedule_file))
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
