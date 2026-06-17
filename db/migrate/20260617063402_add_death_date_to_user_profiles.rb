class AddDeathDateToUserProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :user_profiles, :death_date, :date
  end
end
