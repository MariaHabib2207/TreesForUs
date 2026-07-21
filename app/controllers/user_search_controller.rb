class UserSearchController < ApplicationController
  before_action :authenticate_user!

  def index
    query = params[:q].to_s.strip
    return render json: { results: [] } if query.blank?

    q = "%#{query.downcase}%"

    users = User.where.not(id: current_user.id)
                .where(profile_visibility: "public")
                .where(
                  "LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q OR LOWER(email) LIKE :q",
                  q: q
                )
                .limit(15)

    results = users.map do |user|
      family_name = user.family_memberships.first&.family&.name

      {
        id: user.id,
        name: user.full_name,
        email: user.email,
        family_name: family_name,
        avatar_url: avatar_url_for(user),
        initials: user.initials,
        profile_path: user_profile_path(user)
      }
    end

    render json: { results: results }
  end

def gameroom_index
  query = params[:q].to_s.strip
  return render json: { results: [] } if query.blank?

  q = "%#{query.downcase}%"
  users = User.where.not(id: current_user.id)
              .where(profile_visibility: "public")
              .where("LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q OR LOWER(email) LIKE :q", q: q)
              .limit(15)

  results = users.map do |u|
    existing = GameSession.between(current_user, u)
    {
      id: u.id,
      name: u.full_name,
      initials: u.initials,
      avatar_url: avatar_url_for(u),
      existing_game_session_id: existing&.id
    }
  end

  render json: { results: results }
end
  private

  def avatar_url_for(user)
    return nil unless user.can_view?(:avatar, current_user)

    avatar = user.user_profile&.avatar
    return nil unless avatar&.attached?

    url_for(avatar)
  end
end
