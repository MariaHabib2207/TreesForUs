# db/migrate/20260717030200_add_privacy_columns_to_chatroom_members.rb
class AddPrivacyColumnsToChatroomMembers < ActiveRecord::Migration[8.0]
  def change
    add_column :chatroom_members, :hidden_at, :datetime
    add_column :chatroom_members, :content_blurred, :boolean, default: false, null: false
    add_index :chatroom_members, :hidden_at
  end
end
