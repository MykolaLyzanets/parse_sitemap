# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, skip: %i[registrations]

  authenticated :user do
    root to: 'dashboard/sites#index', as: :authenticated_root
  end

  unauthenticated :user do
    root to: redirect('/users/sign_in')
  end

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  get '(*path)', to: redirect { |_params, request|
    request.original_url.sub('www.', '')
  }, constraints: { host: /^www\./ }

  %w[en ru ua].each do |locale|
    get "/#{locale}", to: redirect('/')
    get "/#{locale}/*path", to: redirect('/%{path}')
  end

  namespace :dashboard do
    root to: 'sites#index'
    resources :sites, only: %i[index show] do
      member do
        post :start_scan
        get :removed_urls
      end
      resources :scans, only: %i[show]
    end
  end

  match '*path', to: 'home#not_found', via: :all, constraints: lambda { |req|
    req.path.exclude?('uploads')
  }
end
