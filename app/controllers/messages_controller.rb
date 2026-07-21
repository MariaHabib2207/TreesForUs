class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chatroom, only: [ :index, :create, :poll ]
  before_action :set_message, only: [ :destroy ]

  def index
    @messages = @chatroom.messages.order(:created_at).visible_for(current_user)
    mark_delivered_and_broadcast(@messages)

    render json: {
      messages_html: render_to_string(
        partial: "messages/message",
        collection: @messages,
        as: :message,
        locals: { current_user_id: current_user.id },
        formats: [ :html ],
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
          formats: [ :html ],
          layout: false
        )
      }, status: :ok
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def poll
    messages = @chatroom.messages.order(:created_at).visible_for(current_user)
    messages = messages.where("messages.id > ?", params[:after]) if params[:after].present?
    mark_delivered_and_broadcast(messages)

    render json: {
      messages_html: render_to_string(
        partial: "messages/message",
        collection: messages,
        as: :message,
        locals: { current_user_id: current_user.id },
        formats: [ :html ],
        layout: false
      )
    }
  end

  def destroy
    unless @message.chatroom.members.exists?(id: current_user.id)
      return head :forbidden
    end

    case params[:scope]
    when "everyone"
      unless @message.user_id == current_user.id
        return render json: { error: "You can only delete your own messages for everyone." }, status: :forbidden
      end
      @message.delete_for_everyone!(current_user)
      broadcast_deletion(@message)
    else
      @message.hide_for(current_user)
    end

    head :ok
  end

  private

  def set_chatroom
    @chatroom = current_user.chatrooms.find(params[:chatroom_id])
  end

  def set_message
    @message = Message.find(params[:id])
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
      formats: [ :html ],
      layout: false
    )
    ChatroomChannel.broadcast_to(@chatroom, { message_html: html, sender_id: @message.user_id })
    other_member = @chatroom.members.where.not(id: current_user.id).first
    return unless other_member&.online?

    @message.update_column(:delivered_at, Time.current)
    ChatroomChannel.broadcast_to(@chatroom, { delivered_message_ids: [ @message.id ] })
  end

  def broadcast_deletion(message)
    ChatroomChannel.broadcast_to(
      message.chatroom,
      { deleted_message_id: message.id, deleted_for_everyone: true }
    )
  end
  def mark_delivered_and_broadcast(messages)
    newly_delivered_ids = messages
      .where.not(user_id: current_user.id)
      .where(delivered_at: nil)
      .pluck(:id)
    return if newly_delivered_ids.empty?

    Message.where(id: newly_delivered_ids).update_all(delivered_at: Time.current)
    ChatroomChannel.broadcast_to(@chatroom, { delivered_message_ids: newly_delivered_ids })
  end
end
