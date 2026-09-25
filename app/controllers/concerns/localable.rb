# frozen_string_literal: true

module Localable
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale, protocol: 'http' }
  end

  private

  def switch_locale(&)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &)
  end
end
