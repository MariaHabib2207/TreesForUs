class ChatroomsController < ApplicationController
  before_action :authenticate_user!

  def index
    @chatrooms = Chatroom.joins(:chatroom_members)
                        .where(chatroom_members: { user_id: current_user.id, hidden_at: nil })
                        .includes(:members, :messages)
                        .order(updated_at: :desc)

    @recent_calls = Call.involving(current_user).visible_to(current_user).includes(:caller, :callee, :chatroom).recent_first.limit(6)
  end
    def show
      @chatroom = Chatroom.joins(:chatroom_members)
                          .where(chatroom_members: { user_id: current_user.id })
                          .find(params[:id])

      @messages = @chatroom.messages
                            .includes(:user, attachments_attachments: :blob)
                            .ordered
                            .visible_for(current_user)

      newly_read_ids = @chatroom.messages.where(read_at: nil).where.not(user: current_user).pluck(:id)
      if newly_read_ids.any?
        @chatroom.messages.where(id: newly_read_ids).update_all(read_at: Time.current, delivered_at: Time.current)
        ChatroomChannel.broadcast_to(@chatroom, { read_message_ids: newly_read_ids })
      end

      @other_members     = @chatroom.members.where.not(id: current_user.id)
      @other_member      = @other_members.first
      @available_friends = @chatroom.available_friends_for(current_user)
      @membership        = ChatroomMember.find_by(chatroom_id: @chatroom.id, user_id: current_user.id)

      @show_other_last_seen = @other_member.nil? || @other_member.can_view?(:last_seen, current_user)
      @show_other_online    = @other_member.nil? || @other_member.can_view?(:online, current_user)
      @show_other_avatar    = @other_member.nil? || @other_member.can_view?(:avatar, current_user)
    end

  def invite_member
    @chatroom = Chatroom.joins(:chatroom_members)
                        .where(chatroom_members: { user_id: current_user.id })
                        .find(params[:id])
    recipient = User.find(params[:recipient_id])

    if @chatroom.members.include?(recipient)
      respond_to do |format|
        format.json { render json: { error: "#{recipient.first_name} is already in this chat." }, status: :unprocessable_entity }
        format.html { redirect_back fallback_location: chatroom_path(@chatroom), alert: "#{recipient.first_name} is already in this chat." }
      end
      return
    end

    already_invited = recipient.noticed_notifications
                               .where(read_at: nil)
                               .joins(:event)
                               .where(noticed_events: { type: "ChatroomInviteNotifier" })
                               .where("noticed_notifications.created_at > ?", 10.minutes.ago)
                               .exists?

    if already_invited
      respond_to do |format|
        format.json { render json: { notice: "Invite already sent to #{recipient.first_name}." }, status: :ok }
        format.html { redirect_back fallback_location: chatroom_path(@chatroom), notice: "Invite already sent to #{recipient.first_name}." }
      end
    else
      other_names = @chatroom.members.where.not(id: [ current_user.id, recipient.id ]).pluck(:first_name)
      with_names  = other_names.any? ? " with #{other_names.join(', ')}" : ""

      ::ChatroomInviteNotifier.with(
        message: "#{current_user.full_name} invited you to join a chat#{with_names}.",
        inviter_id: current_user.id,
        chatroom_id: @chatroom.id
      ).deliver(recipient)

      respond_to do |format|
        format.json { render json: { notice: "Invite sent to #{recipient.first_name}!" }, status: :ok }
        format.html { redirect_back fallback_location: chatroom_path(@chatroom), notice: "Invite sent to #{recipient.first_name}!" }
      end
    end
  end
end
