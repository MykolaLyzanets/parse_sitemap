# frozen_string_literal: true

module Dashboard
  class BaseController < ApplicationController
    layout 'dashboard'

    before_action :authenticate_user!
  end
end
