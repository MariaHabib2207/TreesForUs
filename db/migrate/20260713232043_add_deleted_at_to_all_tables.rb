class AddDeletedAtToAllTables < ActiveRecord::Migration[8.0]
      def change
    tables = [
      :users,
      :user_profiles,
      :families,
      :family_memberships,
      :user_parent_child_relationships,
      :user_partners,
      :family_codes,
      :messages,
      :calls,
      :activities,
      :chatrooms,
      :chatroom_members,
      :friendships,
      :life_activities,
      :family_codes,
      :messages
    ]

    tables.each do |table|
      add_column table, :deleted_at, :datetime unless column_exists?(table, :deleted_at)
      add_index table, :deleted_at unless index_exists?(table, :deleted_at)
    end
  end
end
