
class AddDeliveredAtToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :delivered_at, :datetime
    add_index :messages, :delivered_at
  end
end