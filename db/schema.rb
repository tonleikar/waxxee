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

ActiveRecord::Schema[8.1].define(version: 2026_03_17_150453) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "folder_vinyls", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "folder_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_vinyl_id", null: false
    t.index ["folder_id"], name: "index_folder_vinyls_on_folder_id"
    t.index ["user_vinyl_id"], name: "index_folder_vinyls_on_user_vinyl_id"
  end

  create_table "folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_folders_on_user_id"
  end

  create_table "followers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "followed_id", null: false
    t.bigint "follower_id", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_followers_on_followed_id"
    t.index ["follower_id"], name: "index_followers_on_follower_id"
  end

  create_table "personas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "genres", default: [], null: false
    t.string "image_credit"
    t.string "image_url"
    t.json "keywords", default: [], null: false
    t.string "llm_model"
    t.integer "max_year", default: 2026, null: false
    t.integer "min_year", default: 1900, null: false
    t.boolean "primary_profile", default: false, null: false
    t.text "prompt"
    t.boolean "staff_pick", default: false, null: false
    t.text "summary"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.bigint "user_id"
    t.index ["user_id"], name: "index_personas_on_user_id"
  end

  create_table "swipe_pools", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "next_page", default: 1, null: false
    t.string "persona_signature", null: false
    t.json "remaining_payloads", default: [], null: false
    t.json "seen_keys", default: [], null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "persona_signature"], name: "index_swipe_pools_on_user_id_and_persona_signature", unique: true
    t.index ["user_id"], name: "index_swipe_pools_on_user_id"
  end

  create_table "user_vinyls", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "vinyl_id", null: false
    t.index ["user_id"], name: "index_user_vinyls_on_user_id"
    t.index ["vinyl_id"], name: "index_user_vinyls_on_vinyl_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_source_type", default: "generated", null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "favorite_genre"
    t.bigint "favorite_vinyl_id"
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.text "spotify_access_token"
    t.string "spotify_product"
    t.text "spotify_refresh_token"
    t.datetime "spotify_token_expires_at"
    t.string "spotify_user_id"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["favorite_vinyl_id"], name: "index_users_on_favorite_vinyl_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["spotify_user_id"], name: "index_users_on_spotify_user_id"
    t.index ["username"], name: "index_users_on_username"
  end

  create_table "vinyls", force: :cascade do |t|
    t.string "artist"
    t.string "artwork_url"
    t.datetime "created_at", null: false
    t.string "discogs_url"
    t.string "format"
    t.string "genre"
    t.string "title"
    t.json "tracks"
    t.datetime "updated_at", null: false
    t.integer "year"
  end

  add_foreign_key "folder_vinyls", "folders"
  add_foreign_key "folder_vinyls", "user_vinyls"
  add_foreign_key "folders", "users"
  add_foreign_key "followers", "users", column: "followed_id"
  add_foreign_key "followers", "users", column: "follower_id"
  add_foreign_key "personas", "users"
  add_foreign_key "swipe_pools", "users"
  add_foreign_key "user_vinyls", "users"
  add_foreign_key "user_vinyls", "vinyls"
  add_foreign_key "users", "vinyls", column: "favorite_vinyl_id"
end
