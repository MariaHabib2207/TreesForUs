class FriendshipsController < ApplicationController
  before_action :authenticate_user!

  def new
    @user = User.new
    @user.build_user_profile
    @anchor_id   = params[:user_id]
    @anchor      = User.find_by(id: @anchor_id)
    @family_id   = params[:family_id].presence || current_user.family_ids.first
    @active_family = current_user.families.find_by(id: @family_id)
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
    @family    = current_user.families.find_by(id: @family_id)
    anchor     = User.find_by(id: params[:user_id]) || current_user

    ActiveRecord::Base.transaction do
      @user.save!

      FamilyMembership.create!(
        user:            @user,
        family:          @family,
        membership_type: "friend"
      )

      Friendship.create!(user: anchor, friend: @user)
      Friendship.create!(user: @user, friend: anchor)
    end

    redirect_to authenticated_root_path, notice: "Friend added successfully."

  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def destroy
    friendship = current_user.friendships.find_by(friend_id: params[:id])
    if friendship
      ActiveRecord::Base.transaction do
        Friendship.where(user: current_user, friend_id: params[:id]).destroy_all
        Friendship.where(user_id: params[:id], friend: current_user).destroy_all
      end
      redirect_to authenticated_root_path, notice: "Friend removed."
    else
      redirect_to authenticated_root_path, alert: "Friendship not found."
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
      user_profile_attributes: [ :birth_date, :gender, :phone, :occupation, :address, :avatar ]
    )
  end
end
