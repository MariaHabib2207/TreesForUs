class Rnerer < ActiveRecord::Migration[8.0]
    def change
      # Copy data out first
      execute "CREATE TABLE messages_temp AS SELECT * FROM messages"
      
      drop_table :messages
      
      create_table :messages, force: :cascade do |t|
        t.integer :chatroom_id
        t.integer :user_id
        t.text :body
        t.timestamps
      end

      execute "INSERT INTO messages (id, body, chatroom_id, user_id, created_at, updated_at)
              SELECT id, body, chatroom_id, user_id, created_at, updated_at FROM messages_temp"

      execute "DROP TABLE messages_temp"
    end
end
