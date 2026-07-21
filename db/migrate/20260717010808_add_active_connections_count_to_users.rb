# db/migrate/20260717010000_add_active_connections_count_to_users.rb
class AddActiveConnectionsCountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :active_connections_count, :integer, default: 0, null: false
  end
end
