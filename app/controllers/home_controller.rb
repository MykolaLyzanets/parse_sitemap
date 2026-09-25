# frozen_string_literal: true

class HomeController < ApplicationController
  def index; end

  def not_found
    render template: 'home/not_found', status: :not_found
  end
end
