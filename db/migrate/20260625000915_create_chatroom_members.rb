class CreateChatroomMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :chatroom_members do |t|
      t.integer :chatroom_id
      t.integer :user_id

      t.timestamps
    end
  end
end
