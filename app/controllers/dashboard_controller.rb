class DashboardController < ApplicationController
  before_action :authenticate_user!

def index  
  @user = current_user
  @user_profile = @user.user_profile


  @active_family = resolve_active_family
  return unless @active_family.present?
  @family_type = current_user.family_memberships.last&.membership_type
  if @active_family.family_memberships.last&.membership_type == "friend"
    @friend_members = @active_family.family_memberships
                                    .where.not(user: current_user)
                                    .includes(user: :user_profile)
                                    .map { |m| { user: m.user, profile: m.user.user_profile } }
    return
  end


  preload_family_relationships

  @family_user_ids = @preloaded_users.map(&:id)

  @root_member = find_root_member_in_family(@active_family)
  @family_tree = @root_member.present? ? build_family_tree(@root_member) : nil
end
  private

  def resolve_active_family 
    family_id =
      if params[:family_id].present?
        params[:family_id].to_i
      elsif current_user.family_ids.one?
        current_user.family_ids.first
      end

    current_user.families.find_by(id: family_id) ||
      current_user.families.first
  end

  def preload_family_relationships
    @preloaded_users = User
      .includes(
        :parents,
        :children,
        :user_profile,
        user_partners: :partner,
        inverse_user_partners: :user,
        user_profile: { avatar_attachment: :blob }
      )
      .joins(:family_memberships)
      .where(family_memberships: { family_id: @active_family.id })
      .distinct
  end

  def find_root_member_in_family(family)
    return nil unless family

    family_user_ids = @family_user_ids

    user = current_user
    return nil unless family_user_ids.include?(user.id)

    current = user
    visited = Set.new

    while current.parents.any?
      break if visited.include?(current.id)

      visited.add(current.id)

      parent = current.parents.find do |p|
        family_user_ids.include?(p.id)
      end

      break unless parent

      current = parent
    end

    current
  end

  def build_family_tree(user, visited = Set.new)
    return nil if user.nil?
    return nil if visited.include?(user.id)

    visited.add(user.id)

    partners = partner_ids_for(user)

    {
      user: user,
      profile: user.user_profile,
      partners: partners,
      children: children_of(user, partners).map do |child|
        build_family_tree(child, visited)
      end.compact
    }
  end


  def partner_ids_for(user)
    ids = UserPartner
      .where("user_id = ? OR partner_id = ?", user.id, user.id)
      .pluck(:user_id, :partner_id)
      .flatten
      .uniq
      .reject { |id| id == user.id }

    User
      .includes(:user_profile)
      .where(id: ids)
      .where(id: @family_user_ids)
  end


  def children_of(user, partners)
    parent_ids = [user.id] + Array(partners).map(&:id)

    User
      .joins(:parent_relationships)
      .where(user_parent_child_relationships: {
        parent_id: parent_ids
      })
      .where(id: @family_user_ids)
      .distinct
  end
end