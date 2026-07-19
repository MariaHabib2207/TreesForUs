class ChatroomMembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_membership

  def toggle_hidden
    if @membership.hidden_at?
      @membership.update_column(:hidden_at, nil)
    else
      @membership.update_column(:hidden_at, Time.current)
    end
    render json: { hidden: @membership.hidden_at.present? }
  end

  def toggle_blur
    @membership.update_column(:content_blurred, !@membership.content_blurred)
    render json: { blurred: @membership.content_blurred }
  end

  private

  def set_membership
    @membership = ChatroomMember.find_by!(chatroom_id: params[:chatroom_id], user_id: current_user.id)
  end
end