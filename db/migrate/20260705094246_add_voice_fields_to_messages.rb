class AddVoiceFieldsToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :message_type, :string, default: "text", null: false
    add_column :messages, :duration_in_seconds, :integer
    add_index :messages, :message_type
  end
end
