class CallChannel < ApplicationCable::Channel
  def subscribed
    @chatroom = Chatroom.find(params[:chatroom_id])
    stream_for @chatroom
  end

  def signal(data)
    CallChannel.broadcast_to(@chatroom, {
      type: data["type"],
      payload: data["payload"],
      sender_id: current_user.id
    })
  end
end