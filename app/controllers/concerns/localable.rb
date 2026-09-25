# frozen_string_literal: true

module Localable
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  def default_url_options
    { protocol: 'http' }
  end

  private

  def switch_locale(&)
    I18n.with_locale(I18n.default_locale, &)
  end
end
