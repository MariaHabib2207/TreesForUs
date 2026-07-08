class ChatroomChannel < ApplicationCable::Channel
  def subscribed
    chatroom = Chatroom.find(params[:chatroom_id])
    if chatroom.members.include?(current_user)
      stream_for chatroom
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end
end