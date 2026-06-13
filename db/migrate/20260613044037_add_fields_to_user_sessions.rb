class AddFieldsToUserSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :user_sessions, :zip, :string
    add_column :user_sessions, :continent, :string
  end
end
