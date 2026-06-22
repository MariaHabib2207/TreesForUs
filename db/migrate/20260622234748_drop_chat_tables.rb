class DropChatTables < ActiveRecord::Migration[8.0]
  def change
    drop_table :messages
    drop_table :room_invites
    drop_table :room_memberships
    drop_table :rooms
  end
end
