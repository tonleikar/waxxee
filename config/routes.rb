Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root to: "pages#home_logged_in", as: :authenticated_root
  end

  devise_scope :user do
    unauthenticated do
      root to: "devise/sessions#new", as: :unauthenticated_root
    end
  end

  resources :users, only: [:index]
  resources :feed, only: [:index], controller: :followers
  resources :followers, only: [:index, :create, :destroy]
  resources :collections, controller: :folders, only: [:create, :destroy]
  resources :folder_vinyls, only: [:create, :destroy]
  resources :swiper, only: [:index]
  resources :profile, only: [:show, :edit, :update, :destroy] do
    patch :avatar, on: :member
    get :avatar_preview, on: :member
  end
  resources :user_vinyls, only: [:create, :destroy]
  resources :vinyls, only: [:index, :show]
  resources :discogs, only: [:index, :create]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  #

end
