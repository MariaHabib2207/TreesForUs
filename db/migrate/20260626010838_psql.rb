class Psql < ActiveRecord::Migration[8.0]
def up
  execute "SELECT setval('messages_id_seq', (SELECT MAX(id) FROM messages) + 1)"
end

def down
  # irreversible
end
end
