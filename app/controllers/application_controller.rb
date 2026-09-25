# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Localable

  protect_from_forgery with: :exception

  def after_sign_in_path_for(_resource)
    dashboard_root_path
  end
end
