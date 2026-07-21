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
    ActionCable.server.broadcast(
      "presence_#{current_user.id}",
      { user_id: current_user.id, status: status, last_active_at: current_user.last_active_at&.iso8601 }
    )
  end
end
