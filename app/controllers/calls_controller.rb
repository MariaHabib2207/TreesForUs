class CallsController < ApplicationController
  before_action :set_chatroom

  # Logs a missed call and notifies the recipient. Called by the JS when a
  # call the current user placed times out or is never answered.
  def create
    recipient = User.find(params[:recipient_id])
    MissedCallNotifier.with(chatroom: @chatroom, caller: current_user).deliver(recipient)
    head :ok
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  def set_chatroom
    @chatroom = Chatroom.find(params[:chatroom_id])
  end
end