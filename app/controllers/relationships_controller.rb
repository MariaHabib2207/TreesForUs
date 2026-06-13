class RelationshipsController < ApplicationController
  before_action :authenticate_user!
def new

  @user = User.new
  @user.build_user_profile
  parent_id = params[:parent_id].presence || params[:user_id]
  @parent = User.find_by(id: parent_id)
  @family_id =params[:family_id].presence || current_user.family_ids.first
  @active_family =
    current_user.families.find_by(id: @family_id)
end
 
def create
  @user = User.new(user_params)
  @user.login_enabled = ActiveModel::Type::Boolean.new.cast(
    params[:user][:login_enabled]
  )
  unless @user.login_enabled?
    @user.email = nil
    @user.password = nil
    @user.password_confirmation = nil
  end
  @user.role = @user.login_enabled? ? "family_manager" : "viewer"
  @family_id = params[:family_id].presence || current_user.family_ids.first

  @family = current_user.families.find_by(id: @family_id)
  @parent = User.find_by(
  id: params[:parent_id] || params[:user_id]
)
  if @user.save
    FamilyMembership.create!(
      user: @user,
      family: @family,
      membership_type: "birth"
    )
    if @parent.present?
      UserParentRelationship.create!(
        parent_id: @parent.id,
        child_id: @user.id
      )
    end

    redirect_to authenticated_root_path,
                notice: "Member created successfully."

  else

    render :new,
           status: :unprocessable_entity
  end
end
  private
 
def user_params
  params.require(:user).permit(
    :id,
    :first_name, :last_name,
    :identification_type, :identification_number,
    :status, :login_enabled,
    :role,
    :email, :password, :password_confirmation,
    user_profile_attributes: [:birth_date, :gender, :phone, :occupation, :address, :avatar]
  )
  end

  def user_partner_params
  params.require(:user_partner).permit(
    :partner_id,
    :family_id,
    :membership_type,
    partner_attributes: [
      :first_name,
      :last_name,
      :identification_type,
      :identification_number,
      :email,
      :password,
      :password_confirmation,
      user_profile_attributes: [
        :birth_date,
        :gender,
        :phone,
        :occupation,
        :address,
        :avatar
      ]
    ]
  )
end
end