class UserStatusChannel < ApplicationCable::Channel
  def subscribed
    other_user = User.find(params[:user_id])
    stream_from "presence_#{other_user.id}"
    transmit({
      user_id: other_user.id,
      status: other_user.online? ? "online" : "offline",
      last_active_at: other_user.last_active_at&.iso8601
    })
  end
end
