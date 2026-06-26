class MessagesController < ApplicationController
  before_action :authenticate_user!

def create
  @chatroom = Chatroom.joins(:chatroom_members)
                      .where(chatroom_members: { user_id: current_user.id })
                      .find(params[:chatroom_id])

  message_params = params[:message] || params
  
  @message = @chatroom.messages.build(
    user: current_user,
    body: message_params[:body]
  )

  if message_params[:attachments].present?
    @message.attachments.attach(message_params[:attachments])
  end

  if @message.save
    ChatroomChannel.broadcast_to(
      @chatroom,
      {
        message_html: render_to_string(
          partial: "messages/message",
          locals: { message: @message, current_user: current_user }
        )
      }
    )
    head :ok
  else
    head :unprocessable_entity
  end
end
end