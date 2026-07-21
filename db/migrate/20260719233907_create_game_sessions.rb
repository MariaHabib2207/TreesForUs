class CreateGameSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :game_sessions do |t|
      t.references :player_x, foreign_key: { to_table: :users }, null: false
      t.references :player_o, foreign_key: { to_table: :users }, null: false
      t.string :status, default: "pending", null: false
      t.string :board, default: "---------", null: false
      t.string :turn, default: "x", null: false
      t.references :winner, foreign_key: { to_table: :users }, null: true
      t.timestamps
    end
    add_index :game_sessions, :status
  end
end
