#
class CreateLifeActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :life_activities do |t|
      t.references :user,       null: false, foreign_key: true
      t.string     :title,      null: false
      t.text       :description
      t.string     :category,   null: false
      t.date       :occurred_on
      t.string     :location
      t.string     :visibility, null: false, default: "friends_and_family"
      t.timestamps
    end
    add_index :life_activities, [:user_id, :occurred_on]
    add_index :life_activities, :visibility
  end
end