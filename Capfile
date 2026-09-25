# frozen_string_literal: true

require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/scm/git'
require 'capistrano/rails'
require 'capistrano/bundler'
require 'capistrano/rvm'
require 'capistrano/puma'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
# require 'capistrano/sidekiq'

install_plugin Capistrano::SCM::Git
#
# install_plugin Capistrano::Sidekiq
# install_plugin Capistrano::Sidekiq::Systemd

install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
