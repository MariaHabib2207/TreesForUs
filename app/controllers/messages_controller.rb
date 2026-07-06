class MessagesController < ApplicationController
  before_action :set_chatroom

 def create
  @chatroom = Chatroom.find(params[:chatroom_id])
  message = @chatroom.messages.build(message_params)
  message.user = current_user

  if message.save
    ChatroomChannel.broadcast_to(
      @chatroom,
      message_html: render_to_string(
        partial: "messages/message",
        locals: { message: message, current_user_id: message.user_id }
      ),
      sender_id: message.user_id
    )
    head :ok
  else
    render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
  end
end

  private

  def set_chatroom
    @chatroom = Chatroom.find(params[:chatroom_id])
  end

  def message_params
    params.require(:message).permit(:body, :duration_in_seconds, attachments: [])
  end

  # duration_in_seconds is only ever set by the voice-recorder JS flow, so it's
  # a more reliable signal than content_type sniffing (which can misidentify
  # audio-only webm as "video/webm" — see fix_voice_note_content_types below).
  def infer_message_type(message)
    return "voice" if message.duration_in_seconds.present?
    return "image" if message.attachments.any? { |a| a.content_type.to_s.start_with?("image/") }
    return "file" if message.attachments.any?
    "text"
  end

  # The browser's MediaRecorder produces audio-only webm/mp4, but ActiveStorage's
  # content-type sniffing sometimes tags ambiguous webm containers as "video/webm"
  # since webm can hold video+audio. We know these are voice recordings (attached
  # with duration_in_seconds and no body), so force the correct audio/* content_type
  # rather than relying on sniffing.
  def fix_voice_note_content_types
    return unless @message.duration_in_seconds.present?

    @message.attachments.each do |attachment|
      next unless attachment.blob.content_type == "video/webm" || attachment.blob.filename.to_s.start_with?("voice-")
      attachment.blob.update!(content_type: attachment.blob.content_type.sub("video/", "audio/"))
    end
  end

  # Broadcasts raw data, NOT pre-rendered HTML with a baked-in current_user.
  # Rendering once with the sender's perspective and blasting that same HTML
  # to every subscriber is what caused the audio/"is_mine" bug — each client
  # needs to decide "is this mine?" for itself.
  #
  # NOTE: ActionCable.server.broadcast takes two positional args (channel, message).
  # Passing bare `key: value` pairs here (without literal braces) gets swallowed
  # as Ruby keyword arguments instead of a single positional Hash, which raises
  # "wrong number of arguments (given 1, expected 2)". The { } below is required.
  def broadcast_message
    html = ApplicationController.render(
      partial: "messages/message",
      locals: { message: @message, current_user_id: nil }
    )
    ActionCable.server.broadcast(
      "chatroom_#{@chatroom.id}",
      { message_html: html, sender_id: @message.user_id }
    )
  end
end