class CreateUserProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_profiles do |t|
      t.timestamps
      t.integer :user_id, null: false
      t.date :birth_date
      t.string :gender
      t.string :marital_status
      t.string :occupation
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.string :phone
      t.string :nationality
      t.integer :created_by
      t.integer :updated_by
      t.string :current_status
    end
    add_index :user_profiles, :user_id, name: "index_user_profiles_on_user_id"
  end
end
