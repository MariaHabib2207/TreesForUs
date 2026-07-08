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
  resources :friendships, only: [:new, :create, :destroy]
  resources :user_profiles

  resources :users do
    resources :user_partners, only: [:new, :create]
    resources :invitations, only: [:new, :create]
    resources :life_activities, only: %i[index new create edit update destroy]
  end

  get   "identification", to: "identification#edit",   as: :edit_identification
  patch "identification", to: "identification#update", as: :update_identification

  resources :relationships, only: [:create, :destroy, :new]

  scope "/invitations/:token" do
    get   "accept", to: "accept_invitations#edit",   as: :accept_invitation
    patch "accept", to: "accept_invitations#update", as: :update_invitation
  end

  resources :chatrooms, only: [:show, :index, :destroy] do
    resources :messages, only: [:create, :index] do
      collection do
        get :poll
      end
    end
    member { post :invite_member }
  end

  post "notifications/accept_chatroom_invite", to: "notifications#accept_chatroom_invite", as: :accept_chatroom_invite_notifications
  post "notifications/reject_chatroom_invite", to: "notifications#reject_chatroom_invite", as: :reject_chatroom_invite_notifications

  resources :notifications, only: [:index, :destroy] do
    collection do
      patch :mark_all_read
      post :invite_to_chat
      post :accept_chat_invite
      post :reject_chat_invite
    end
    member do
      patch :mark_read
    end
  end

  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end

  unauthenticated do
    root to: redirect("/users/sign_in")
  end

  get "up" => "rails/health#show", as: :rails_health_check
  mount ActionCable.server => '/cable'
  get '/sitemap.xml', to: 'sitemaps#show', defaults: { format: 'xml' }
end