class CallsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_call, only: [:destroy]

  # GET /calls — the WhatsApp-style call log, scoped to calls involving the
  # current user and excluding anything they've deleted (hidden) for
  # themselves.
  def index
    @calls = Call
      .involving(current_user)
      .visible_to(current_user)
      .includes(:caller, :callee, chatroom: {})
      .recent_first
  end

  # POST /chatrooms/:chatroom_id/calls
  # Called once, by the caller's browser only (see call_session.js /
  # teardownCall), whenever a call they placed ends — answered, missed,
  # declined, or busy. Creates the Call row (source of truth for the call
  # log) and a matching Message (message_type: "call") so the summary shows
  # up inline in the chatroom exactly like a normal message.
  def create
    chatroom = current_user.chatrooms.find(params[:chatroom_id])
    recipient = User.find(params[:recipient_id])

    call_type = params[:call_type].to_s
    call_type = "audio" unless Call.call_types.key?(call_type)

    status = params[:status].to_s
    status = "missed" unless Call.statuses.key?(status)

    duration = params[:duration_in_seconds].to_i
    duration = 0 if duration.negative?
    # Only an "answered" call should ever carry a nonzero duration.
    duration = 0 unless status == "answered"

    call = Call.create!(
      chatroom: chatroom,
      caller: current_user,
      callee: recipient,
      call_type: call_type,
      status: status,
      duration_in_seconds: duration,
      ended_at: Time.current
    )

    message = chatroom.messages.create!(
      user: current_user,
      message_type: "call",
      call: call,
      duration_in_seconds: duration,
      body: call_summary_body(call)
    )

    render json: { status: "ok", call_id: call.id, message_id: message.id }, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  # DELETE /calls/:id — "delete" for the call log: hides it for the current
  # user only. The row (and the chat bubble it produced) is untouched.
  def destroy
    @call.hide_for(current_user)

    respond_to do |format|
      format.html { redirect_to calls_path, notice: "Call removed from your call log." }
      format.json { render json: { status: "ok" } }
    end
  end

  private

  def set_call
    @call = Call.involving(current_user).find(params[:id])
  end

  def call_summary_body(call)
    case call.status
    when "missed" then "Missed #{call.call_type} call"
    when "declined" then "Declined #{call.call_type} call"
    when "busy" then "#{call.call_type.capitalize} call — no answer"
    else
      "#{call.call_type.capitalize} call"
    end
  end
end
