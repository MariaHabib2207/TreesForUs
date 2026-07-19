# Subscribed once per browser tab/device, globally, for the lifetime of the
# session (see application.js) — not tied to any single chatroom page.
# Registers this user as "online" for as long as at least one connection
# is open, and broadcasts changes to anyone watching via UserStatusChannel.
class PresenceChannel < ApplicationCable::Channel
  def subscribed
    User.increment_counter(:active_connections_count, current_user.id)
    broadcast_presence("online")
  end

  def unsubscribed
    User.decrement_counter(:active_connections_count, current_user.id) if current_user.active_connections_count.to_i > 0
    current_user.reload
    broadcast_presence("offline") if current_user.active_connections_count.to_i.zero?
  end

  private

  def broadcast_presence(status)
    ActionCable.server.broadcast("presence_#{current_user.id}", { user_id: current_user.id, status: status })
  end
end