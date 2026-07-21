class AddRelatedUserToFamilyCodes < ActiveRecord::Migration[8.0]
  def change
    add_reference :family_codes, :related_user,
                  foreign_key: { to_table: :users },
                  null: true
  end
end
