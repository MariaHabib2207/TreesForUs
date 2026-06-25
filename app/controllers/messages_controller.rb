class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chatroom = Chatroom.joins(:chatroom_members)
                        .where(chatroom_members: { user_id: current_user.id })
                        .find(params[:chatroom_id])

    @message = @chatroom.messages.build(
      user: current_user,
      body: params[:message][:body]
    )

    if params[:message][:attachments].present?
      @message.attachments.attach(params[:message][:attachments])
    end

    if @message.save
      redirect_to chatroom_path(@chatroom)
    else
      redirect_to chatroom_path(@chatroom), alert: "Could not send message."
    end
  end
end