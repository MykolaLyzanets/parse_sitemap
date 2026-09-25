# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.4'

gem 'pg', '~> 1.4.5'
gem 'puma', '~> 5.0'
gem 'rails', '~> 7.0.8'

gem 'cssbundling-rails'
gem 'i18n', '~> 1.14', '>= 1.14.1'
gem 'jsbundling-rails'
gem 'slim', '~> 3.0', '>= 3.0.6'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'

gem 'bootsnap', require: false
gem 'faraday', '~> 2.9'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  gem 'brakeman', '~> 6.0', '>= 6.0.1'
  gem 'fasterer', '~> 0.10.1'
  gem 'simplecov', require: false

  gem 'rubocop', '~> 1.48', '>= 1.48.1', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-performance', '~> 1.16', require: false
  gem 'rubocop-rails', '~> 2.18', require: false
  gem 'rubocop-rspec', '~> 2.19', require: false

  gem 'debug', platforms: %i[mri mingw x64_mingw]
end

group :development do
  gem 'annotate', '~> 3.2'
  gem 'bullet', '~> 7.0', '>= 7.0.7'
  gem 'letter_opener_web', '~> 2.0'
  gem 'pry', '~> 0.14.2'
  gem 'web-console', '~> 4.2'

  gem 'ruby-lsp', '~> 0.17.2'
  gem 'solargraph', '~> 0.50.0'

  gem 'capistrano', require: false
  gem 'capistrano3-puma', '5.2.0'
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rvm', require: false
  gem "capistrano-sidekiq", "~> 3.2.0", require: false
  gem 'capistrano-yarn', require: false
end

group :test do
  gem 'capybara', '~> 3.39', '>= 3.39.1'
  gem 'database_cleaner', '~> 2.0', '>= 2.0.2'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'rspec_junit_formatter', require: false
  gem 'rspec-rails', '~> 6.0.0'
  gem 'shoulda-matchers', '~> 5.3'

  gem 'selenium-webdriver'
  gem 'webdrivers'
end

gem "sidekiq", "~> 7.3"
gem "sidekiq-cron", "~> 2.4"
gem "redis", "~> 6.0"

gem "connection_pool", "~> 2.4"

gem "devise", "~> 4.9"
