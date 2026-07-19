# app/channels/user_status_channel.rb
class UserStatusChannel < ApplicationCable::Channel
  def subscribed
    other_user = User.find(params[:user_id])
    stream_from "presence_#{other_user.id}"
    transmit({ user_id: other_user.id, status: other_user.online? ? "online" : "offline" })
  end
end