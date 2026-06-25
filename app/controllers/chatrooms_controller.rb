class ChatroomsController < ApplicationController
  before_action :authenticate_user!

  def index
    @chatrooms = Chatroom.joins(:chatroom_members)
                         .where(chatroom_members: { user_id: current_user.id })
                         .includes(:members, :messages)
                         .order(updated_at: :desc)
  end

  def show
    @chatroom = Chatroom.joins(:chatroom_members)
                        .where(chatroom_members: { user_id: current_user.id })
                        .find(params[:id])
    @messages = @chatroom.messages.includes(:user, attachments_blobs: :blob).ordered
    @other_member = @chatroom.members.where.not(id: current_user.id).first
  end

  def destroy
    @chatroom = Chatroom.joins(:chatroom_members)
                        .where(chatroom_members: { user_id: current_user.id })
                        .find(params[:id])
    @chatroom.destroy
    redirect_to chatrooms_path, notice: "Chatroom deleted."
  end
end