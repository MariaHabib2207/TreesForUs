class NotificationsController < ApplicationController
  before_action :authenticate_user!
   
  def index
    @notifications = current_user.noticed_notifications
                                 .includes(:event)
                                 .order(created_at: :desc)
                                 .limit(50)
  end
  def mark_read
    notification = current_user.noticed_notifications.find(params[:id])
    notification.update!(read_at: Time.current)
    redirect_back fallback_location: root_path
  end

  def mark_all_read
    current_user.noticed_notifications.where(read_at: nil).update_all(read_at: Time.current)
    redirect_back fallback_location: root_path 
  end
  
  def invite_to_chat
    recipient = User.find(params[:recipient_id])

    already_invited = recipient.noticed_notifications
                              .where(read_at: nil)
                              .joins(:event)
                              .where(noticed_events: { type: "ChatInviteNotifier" })
                              .where("noticed_notifications.created_at > ?", 10.minutes.ago)
                              .exists?

    unless already_invited
      ::ChatInviteNotifier.with(
        message: "#{current_user.full_name} invited you to a chatroom.",
        inviter_id: current_user.id
      ).deliver(recipient)
    end

    redirect_back fallback_location: authenticated_root_path
  end
  def accept_chat_invite
  notification = current_user.noticed_notifications.find(params[:notification_id])
  notification.update!(read_at: Time.current)

  inviter = User.find(params[:inviter_id])

  ::ChatInviteAcceptedNotifier.with(
    message: "#{current_user.full_name} accepted your chat invitation."
  ).deliver(inviter)

  redirect_back fallback_location: authenticated_root_path
end

def reject_chat_invite
  notification = current_user.noticed_notifications.find(params[:notification_id])
  notification.update!(read_at: Time.current)

  inviter = User.find(params[:inviter_id])

  ::ChatInviteRejectedNotifier.with(
    message: "#{current_user.full_name} declined your chat invitation."
  ).deliver(inviter)

  redirect_back fallback_location: authenticated_root_path
end
  def destroy
    notification = current_user.noticed_notifications.find(params[:id])
    notification.destroy
    redirect_back fallback_location: notifications_path
  end

  private
  def serialize(n)
    event_params = n.event.params
    {
      id: n.id,
      message: event_params[:message],
      url: event_params[:url],
      read: n.read_at.present?,
      created_at: n.created_at.strftime("%b %d, %H:%M")
    }
  end
end