Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  resources :families do
    resources :family_memberships
    resources :family_codes, only: [:index, :new, :create, :destroy]
    member do
      get :activity_feed
    end
  end

  resources :activities, only: [:index]

  resources :user_profiles

  resources :users do
    resources :user_partners, only: [:new, :create]
    resources :invitations, only: [:new, :create]
  end

  get  "identification", to: "identification#edit",  as: :edit_identification
  patch "identification", to: "identification#update", as: :update_identification

  resources :relationships, only: [:create, :destroy, :new]

  scope "/invitations/:token" do
    get  "accept", to: "accept_invitations#edit",   as: :accept_invitation
    patch "accept", to: "accept_invitations#update", as: :update_invitation
  end

  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end

  unauthenticated do
    root to: redirect("/users/sign_in")
  end

  get "up" => "rails/health#show", as: :rails_health_check
end