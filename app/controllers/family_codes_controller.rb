# app/controllers/family_codes_controller.rb
class FamilyCodesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_family_manager!
  before_action :set_family

  def index
    @family_codes = @family.family_codes
                           .includes(:used_by)
                           .order(created_at: :desc)
  end

  def new
    @family_code = @family.family_codes.new
  end

  def create
    @family_code = @family.family_codes.new(family_code_params)
    @family_code.created_by = current_user

    if @family_code.save
      FamilyCodeMailer.invite(@family_code).deliver_later
      redirect_to family_family_codes_path(@family),
                  notice: "Invitation sent to #{@family_code.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @family_code = @family.family_codes.find(params[:id])
    @family_code.destroy
    redirect_to family_family_codes_path(@family),
                notice: "Code revoked."
  end

  private

  def set_family
    @family = current_user.families.find(params[:family_id])
  end

  def family_code_params
    params.require(:family_code).permit(:email, :membership_type, :expires_at)
  end

  def require_family_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user.family_manager?
  end
end
