class CreateCalls < ActiveRecord::Migration[8.0]
  def change
    create_table :calls do |t|
      t.references :chatroom, null: false, foreign_key: true
      t.references :caller, null: false, foreign_key: { to_table: :users }
      t.references :callee, null: false, foreign_key: { to_table: :users }
      t.string :call_type, null: false, default: "audio"
      t.string :status, null: false, default: "missed"
      t.integer :duration_in_seconds, default: 0, null: false
      t.datetime :ended_at

      t.timestamps
    end

    add_index :calls, :call_type
    add_index :calls, :status
  end
end
