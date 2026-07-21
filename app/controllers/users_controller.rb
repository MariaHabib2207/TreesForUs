class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]

  def index
    @users = User.all
  end

  def new
    @user = User.new
    @user.parent_id             = params[:parent_id]
    @user.identification_type   = params[:identification_type]
    @user.identification_number = params[:identification_number]
    @user.status                = params[:status]
    @user.role                  = params[:role]
  end

  def create
    @user = User.new(user_params)
    @user.parent_id             = params[:parent_id]
    @user.identification_type   = params[:identification_type]
    @user.identification_number = params[:identification_number]
    @user.status                = params[:status]
    @user.role                  = params[:role]
    @user.login_enabled         = params[:login_enabled] == "true"

    unless @user.login_enabled?
      @user.email                 = nil
      @user.password              = nil
      @user.password_confirmation = nil
    end

    if @user.save
      if params[:family_id].present?
        FamilyMembership.create(
          user:            @user,
          family_id:       params[:family_id],
          membership_type: params[:membership_type] || :birth
        )
      end

      @user.create_activity :create, owner: current_user

      redirect_to user_profiles_show_path, notice: "Family member created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      @user.create_activity :update, owner: current_user

      redirect_to user_profiles_path, notice: "Family member updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.create_activity :destroy, owner: current_user  # before destroy!
    @user.destroy
    redirect_to authenticated_root_path, notice: "Family member removed."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :password,
      :password_confirmation,
      :login_enabled,
      user_profile_attributes: [
        :birth_date,
        :death_date,
        :gender,
        :marital_status,
        :occupation,
        :address,
        :city,
        :state,
        :zip,
        :country,
        :phone,
        :nationality
      ]
    )
  end
end
