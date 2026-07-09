class MessagesController < ApplicationController
  before_action :set_chatroom

  def index
    @messages = @chatroom.messages.order(:created_at)
    render json: {
      messages_html: render_to_string(
        partial: "messages/message",
        collection: @messages,
        as: :message,
        locals: { current_user_id: current_user.id },
        formats: [:html],
        layout: false
      )
    }
  end

  def create
    @message = @chatroom.messages.build(message_params)
    @message.user = current_user

    if @message.save
      fix_voice_note_content_types
      @message.update_column(:message_type, infer_message_type(@message)) if @message.respond_to?(:message_type)

      broadcast_message

      render json: {
        message_html: render_to_string(
          partial: "messages/message",
          locals: { message: @message, current_user_id: current_user.id },
          formats: [:html],
          layout: false
        )
      }, status: :ok
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def poll
    messages = @chatroom.messages.order(:created_at)
    messages = messages.where("messages.id > ?", params[:after]) if params[:after].present?

    render json: {
      messages_html: render_to_string(
        partial: "messages/message",
        collection: messages,
        as: :message,
        locals: { current_user_id: current_user.id },
        formats: [:html],
        layout: false
      )
    }
  end

  private

  def set_chatroom
    @chatroom = current_user.chatrooms.find(params[:chatroom_id])
  end

  def message_params
    params.require(:message).permit(:body, :duration_in_seconds, attachments: [])
  end

  def infer_message_type(message)
    return "voice" if message.duration_in_seconds.present?
    return "image" if message.attachments.any? { |a| a.content_type.to_s.start_with?("image/") }
    return "file" if message.attachments.any?
    "text"
  end

  def fix_voice_note_content_types
    return unless @message.duration_in_seconds.present?

    @message.attachments.each do |attachment|
      next unless attachment.blob.content_type == "video/webm" || attachment.blob.filename.to_s.start_with?("voice-")
      attachment.blob.update!(content_type: attachment.blob.content_type.sub("video/", "audio/"))
    end
  end

  def broadcast_message
    html = ApplicationController.render(
      partial: "messages/message",
      locals: { message: @message, current_user_id: nil },
      formats: [:html],
      layout: false
    )
    ActionCable.server.broadcast(
      "chatroom_#{@chatroom.id}",
      { message_html: html, sender_id: @message.user_id }
    )
  end
end