# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Localable

  protect_from_forgery with: :exception
end
