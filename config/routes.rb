# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, skip: %i[registrations]

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development? || Rails.env.test?

  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  get '(*path)', to: redirect { |_params, request|
    request.original_url.sub('www.', '')
  }, constraints: { host: /^www\./ }

  scope '(:locale)', locale: /(#{I18n.available_locales.map(&:to_s).join('|')})/ do
    root 'home#index'

    match '*path', to: 'home#not_found', via: :all, constraints: lambda { |req|
      req.path.exclude?('uploads')
    }
  end
end
