# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.before do
    CarrierWave.configure do |carrierwave|
      carrierwave.storage = :file
      carrierwave.enable_processing = false
      carrierwave.root = Rails.root.join('tmp', 'carrierwave')
    end
    FileUtils.mkdir_p(Rails.root.join('tmp', 'carrierwave'))
  end

  config.after do
    FileUtils.rm_rf(Rails.root.join('tmp', 'carrierwave'))
  end
end
