class CallChannel < ApplicationCable::Channel
  def subscribed
    reject and return unless current_user
    stream_for current_user
  end

  def signal(data)
    recipient = User.find_by(id: data["recipient_id"])
    return unless recipient

    chatroom = Chatroom.find_by(id: data["chatroom_id"])
    return if chatroom && !chatroom.members.exists?(id: current_user.id)

    CallChannel.broadcast_to(recipient, {
      type: data["type"],
      payload: data["payload"],
      sender_id: current_user.id,
      sender_name: current_user.full_name,
      sender_avatar_url: avatar_url_for(current_user),
      chatroom_id: data["chatroom_id"]
    })
  end

  private

  def avatar_url_for(user)
    avatar = user.user_profile&.avatar
    return nil unless avatar&.attached?
    Rails.application.routes.url_helpers.rails_blob_path(avatar, only_path: true)
  end
end
