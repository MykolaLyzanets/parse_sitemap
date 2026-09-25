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

ActiveRecord::Schema[7.0].define(version: 2026_09_25_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "scans", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "started_at", null: false
    t.datetime "finished_at"
    t.integer "total_count", default: 0, null: false
    t.integer "added_count", default: 0, null: false
    t.integer "removed_count", default: 0, null: false
    t.integer "unchanged_count", default: 0, null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "added_urls_snapshot"
    t.string "removed_urls_snapshot"
    t.index ["site_id", "finished_at"], name: "index_scans_on_site_id_and_finished_at"
    t.index ["site_id", "status"], name: "index_scans_on_site_id_and_status"
    t.index ["site_id"], name: "index_scans_on_site_id"
  end

  create_table "site_urls", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.text "url", null: false
    t.string "url_digest", limit: 64, null: false
    t.datetime "first_seen_at"
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "url_digest"], name: "index_site_urls_on_site_id_and_url_digest", unique: true
    t.index ["site_id"], name: "index_site_urls_on_site_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "domain", null: false
    t.string "name"
    t.string "sitemap_url"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "snapshot"
    t.index ["domain"], name: "index_sites_on_domain", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "scans", "sites"
  add_foreign_key "site_urls", "sites"
end
