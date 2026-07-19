# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_07_19_044118) do
  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.integer "resource_id"
    t.string "author_type"
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.string "trackable_type"
    t.integer "trackable_id"
    t.string "owner_type"
    t.integer "owner_id"
    t.string "key"
    t.text "parameters"
    t.string "recipient_type"
    t.integer "recipient_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_activities_on_deleted_at"
    t.index ["owner_type", "owner_id"], name: "index_activities_on_owner"
    t.index ["recipient_type", "recipient_id"], name: "index_activities_on_recipient"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "call_hidings", force: :cascade do |t|
    t.integer "call_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["call_id", "user_id"], name: "index_call_hidings_on_call_id_and_user_id", unique: true
    t.index ["call_id"], name: "index_call_hidings_on_call_id"
    t.index ["user_id"], name: "index_call_hidings_on_user_id"
  end

  create_table "calls", force: :cascade do |t|
    t.integer "chatroom_id", null: false
    t.integer "caller_id", null: false
    t.integer "callee_id", null: false
    t.string "call_type", default: "audio", null: false
    t.string "status", default: "missed", null: false
    t.integer "duration_in_seconds", default: 0, null: false
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["call_type"], name: "index_calls_on_call_type"
    t.index ["callee_id"], name: "index_calls_on_callee_id"
    t.index ["caller_id"], name: "index_calls_on_caller_id"
    t.index ["chatroom_id"], name: "index_calls_on_chatroom_id"
    t.index ["deleted_at"], name: "index_calls_on_deleted_at"
    t.index ["status"], name: "index_calls_on_status"
  end

  create_table "chatroom_members", force: :cascade do |t|
    t.integer "chatroom_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.datetime "hidden_at"
    t.boolean "content_blurred", default: false, null: false
    t.index ["deleted_at"], name: "index_chatroom_members_on_deleted_at"
    t.index ["hidden_at"], name: "index_chatroom_members_on_hidden_at"
  end

  create_table "chatrooms", force: :cascade do |t|
    t.string "name"
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_chatrooms_on_deleted_at"
  end

  create_table "families", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_families_on_deleted_at"
  end

  create_table "family_codes", force: :cascade do |t|
    t.integer "family_id", null: false
    t.integer "created_by_id", null: false
    t.string "code", null: false
    t.string "email", null: false
    t.integer "membership_type", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.integer "used_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "related_user_id"
    t.datetime "deleted_at"
    t.index ["code"], name: "index_family_codes_on_code", unique: true
    t.index ["created_by_id"], name: "index_family_codes_on_created_by_id"
    t.index ["deleted_at"], name: "index_family_codes_on_deleted_at"
    t.index ["email"], name: "index_family_codes_on_email"
    t.index ["family_id"], name: "index_family_codes_on_family_id"
    t.index ["related_user_id"], name: "index_family_codes_on_related_user_id"
    t.index ["used_by_id"], name: "index_family_codes_on_used_by_id"
  end

  create_table "family_memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "family_id", null: false
    t.integer "membership_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_family_memberships_on_deleted_at"
    t.index ["family_id"], name: "index_family_memberships_on_family_id"
    t.index ["user_id"], name: "index_family_memberships_on_user_id"
  end

  create_table "friendships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "friend_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_friendships_on_deleted_at"
    t.index ["friend_id"], name: "index_friendships_on_friend_id"
    t.index ["user_id", "friend_id"], name: "index_friendships_on_user_id_and_friend_id", unique: true
    t.index ["user_id"], name: "index_friendships_on_user_id"
  end

  create_table "life_activities", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "category", null: false
    t.date "occurred_on"
    t.string "location"
    t.string "visibility", default: "friends_and_family", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_life_activities_on_deleted_at"
    t.index ["user_id", "occurred_on"], name: "index_life_activities_on_user_id_and_occurred_on"
    t.index ["user_id"], name: "index_life_activities_on_user_id"
    t.index ["visibility"], name: "index_life_activities_on_visibility"
  end

  create_table "message_deletions", force: :cascade do |t|
    t.integer "message_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "user_id"], name: "index_message_deletions_on_message_id_and_user_id", unique: true
    t.index ["message_id"], name: "index_message_deletions_on_message_id"
    t.index ["user_id"], name: "index_message_deletions_on_user_id"
  end

  create_table "message_hidings", force: :cascade do |t|
    t.integer "message_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "user_id"], name: "index_message_hidings_on_message_id_and_user_id", unique: true
    t.index ["message_id"], name: "index_message_hidings_on_message_id"
    t.index ["user_id"], name: "index_message_hidings_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "chatroom_id"
    t.integer "user_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "read_at"
    t.string "message_type", default: "text", null: false
    t.integer "duration_in_seconds"
    t.integer "call_id"
    t.datetime "deleted_for_everyone_at"
    t.integer "deleted_for_everyone_by_id"
    t.datetime "deleted_at"
    t.datetime "delivered_at"
    t.index ["call_id"], name: "index_messages_on_call_id"
    t.index ["deleted_at"], name: "index_messages_on_deleted_at"
    t.index ["deleted_for_everyone_by_id"], name: "index_messages_on_deleted_for_everyone_by_id"
    t.index ["delivered_at"], name: "index_messages_on_delivered_at"
    t.index ["id"], name: "index_messages_on_id", unique: true
    t.index ["message_type"], name: "index_messages_on_message_type"
  end

  create_table "noticed_events", force: :cascade do |t|
    t.string "type"
    t.string "record_type"
    t.bigint "record_id"
    t.json "params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notifications_count"
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", force: :cascade do |t|
    t.string "type"
    t.bigint "event_id", null: false
    t.string "recipient_type", null: false
    t.bigint "recipient_id", null: false
    t.datetime "read_at", precision: nil
    t.datetime "seen_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "user_parent_child_relationships", force: :cascade do |t|
    t.integer "parent_id"
    t.integer "child_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_user_parent_child_relationships_on_deleted_at"
    t.index ["parent_id", "child_id"], name: "idx_on_parent_id_child_id_94af4b48a2", unique: true
  end

  create_table "user_partners", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "partner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_user_partners_on_deleted_at"
    t.index ["partner_id"], name: "index_user_partners_on_partner_id"
    t.index ["user_id", "partner_id"], name: "index_user_partners_on_user_id_and_partner_id", unique: true
    t.index ["user_id"], name: "index_user_partners_on_user_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.date "birth_date"
    t.string "gender"
    t.string "marital_status"
    t.string "occupation"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
    t.string "phone"
    t.string "nationality"
    t.integer "created_by"
    t.integer "updated_by"
    t.string "current_status"
    t.date "death_date"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_user_profiles_on_deleted_at"
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "user_sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "city"
    t.string "country"
    t.string "region"
    t.string "browser"
    t.string "browser_version"
    t.string "os"
    t.string "os_version"
    t.string "device_type"
    t.string "device_name"
    t.datetime "last_active_at"
    t.string "user_agent"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "zip"
    t.string "continent"
    t.string "device_brand"
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "identification_type", default: 0, null: false
    t.string "identification_number", null: false
    t.integer "status", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.string "email"
    t.string "encrypted_password"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.integer "parent_id"
    t.boolean "login_enabled", default: false, null: false
    t.string "invitation_token"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.string "provider"
    t.string "uid"
    t.string "remember_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "deleted_at"
    t.integer "active_connections_count", default: 0, null: false
    t.string "last_seen_visibility", default: "everyone", null: false
    t.string "online_visibility", default: "everyone", null: false
    t.string "avatar_visibility", default: "everyone", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["identification_type", "identification_number"], name: "index_users_on_id_type_and_number", unique: true
    t.index ["parent_id"], name: "index_users_on_parent_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "visibility_permissions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "viewer_id", null: false
    t.string "setting_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "viewer_id", "setting_type"], name: "index_visibility_permissions_uniqueness", unique: true
    t.index ["user_id"], name: "index_visibility_permissions_on_user_id"
    t.index ["viewer_id"], name: "index_visibility_permissions_on_viewer_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "call_hidings", "calls"
  add_foreign_key "call_hidings", "users"
  add_foreign_key "calls", "chatrooms"
  add_foreign_key "calls", "users", column: "callee_id"
  add_foreign_key "calls", "users", column: "caller_id"
  add_foreign_key "family_codes", "families"
  add_foreign_key "family_codes", "users", column: "created_by_id"
  add_foreign_key "family_codes", "users", column: "related_user_id"
  add_foreign_key "family_codes", "users", column: "used_by_id"
  add_foreign_key "family_memberships", "families"
  add_foreign_key "family_memberships", "users"
  add_foreign_key "friendships", "users"
  add_foreign_key "friendships", "users", column: "friend_id"
  add_foreign_key "life_activities", "users"
  add_foreign_key "message_deletions", "messages"
  add_foreign_key "message_deletions", "users"
  add_foreign_key "message_hidings", "messages"
  add_foreign_key "message_hidings", "users"
  add_foreign_key "messages", "calls"
  add_foreign_key "messages", "users", column: "deleted_for_everyone_by_id"
  add_foreign_key "user_partners", "users"
  add_foreign_key "user_partners", "users", column: "partner_id"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "visibility_permissions", "users"
  add_foreign_key "visibility_permissions", "users", column: "viewer_id"
end
