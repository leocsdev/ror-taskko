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

ActiveRecord::Schema[8.1].define(version: 2026_11_03_092119) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_categories_on_lower_name", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "priority", default: "medium", null: false
    t.datetime "due_at"
    t.datetime "completed_at"
    t.string "ai_suggested_priority"
    t.text "ai_reason"
    t.string "ai_status", default: "not_requested", null: false
    t.datetime "ai_analyzed_at"
    t.bigint "category_id"
    t.bigint "ai_suggested_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_suggested_category_id"], name: "index_tasks_on_ai_suggested_category_id"
    t.index ["category_id"], name: "index_tasks_on_category_id"
    t.check_constraint "ai_status::text = ANY (ARRAY['not_requested'::character varying, 'pending'::character varying, 'completed'::character varying, 'failed'::character varying]::text[])", name: "tasks_ai_status_allowed_values"
    t.check_constraint "ai_suggested_priority IS NULL OR (ai_suggested_priority::text = ANY (ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'urgent'::character varying]::text[]))", name: "tasks_ai_suggested_priority_allowed_values"
    t.check_constraint "priority::text = ANY (ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'urgent'::character varying]::text[])", name: "tasks_priority_allowed_values"
  end

  add_foreign_key "tasks", "categories"
  add_foreign_key "tasks", "categories", column: "ai_suggested_category_id"
end
