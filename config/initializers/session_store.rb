Rails.application.config.session_store :cookie_store,
  key: '_tree_of_us_session',
  secure: Rails.env.production?,
  same_site: :lax