# app/controllers/life_activities_controller.rb
class LifeActivitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity, only: %i[show edit update destroy]
  before_action :set_owner
  before_action :authorize_owner!, only: %i[new create edit update destroy]

  def index
    @activities = @owner.life_activities
                        .visible_to(current_user, @owner)
                        .chronological
                        .includes(photos_attachments: :blob)
  end

  def show; end

  def new
    @activity = @owner.life_activities.build
  end

  def create
    @activity = @owner.life_activities.build(activity_params)
    if @activity.save
      redirect_to user_life_activities_path(@owner),
                  notice: "Activity added to your timeline!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if params[:remove_photo_ids].present?
      @activity.photos.where(id: params[:remove_photo_ids]).purge
    end

    if @activity.update(activity_params)
      redirect_to user_life_activities_path(@owner),
                  notice: "Activity updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @activity.destroy
    redirect_to user_life_activities_path(@owner),
                notice: "Activity removed."
  end

  private

  def set_activity
    @activity = LifeActivity.find(params[:id])
  end

  def set_owner
    @owner = if params[:user_id].present?
               User.find(params[:user_id])
    else
               @activity.user
    end
  end

  def authorize_owner!
    redirect_to root_path, alert: "Not authorised." unless current_user == @owner
  end

  def activity_params
    params.require(:life_activity).permit(
      :title, :description, :category,
      :occurred_on, :location, :visibility,
      photos: []
    )
  end
end
