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

ActiveRecord::Schema[7.2].define(version: 61) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "articles_tags", id: false, force: :cascade do |t|
    t.integer "article_id"
    t.integer "tag_id"
  end

  create_table "blacklist_patterns", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255
    t.string "pattern", limit: 255
    t.index ["pattern"], name: "blacklist_patterns_pattern_index"
  end

  create_table "blogs", id: :serial, force: :cascade do |t|
    t.text "settings"
    t.string "base_url", limit: 255
  end

  create_table "categories", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "position"
    t.string "permalink", limit: 255
    t.index ["permalink"], name: "categories_permalink_index"
  end

  create_table "categorizations", id: :serial, force: :cascade do |t|
    t.integer "article_id"
    t.integer "category_id"
    t.boolean "is_primary"
  end

  create_table "contents", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255
    t.string "title", limit: 255
    t.string "author", limit: 255
    t.text "body"
    t.text "extended"
    t.text "excerpt"
    t.string "keywords", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "permalink", limit: 255
    t.string "guid", limit: 255
    t.integer "text_filter_id"
    t.text "whiteboard"
    t.string "name", limit: 255
    t.boolean "published", default: false
    t.boolean "allow_pings"
    t.boolean "allow_comments"
    t.integer "blog_id", null: false
    t.datetime "published_at", precision: nil
    t.text "state"
    t.index ["blog_id"], name: "contents_blog_id_index"
    t.index ["published"], name: "index_contents_on_published"
    t.index ["text_filter_id"], name: "index_contents_on_text_filter_id"
  end

  create_table "feedback", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255
    t.string "title", limit: 255
    t.string "author", limit: 255
    t.text "body"
    t.text "excerpt"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "guid", limit: 255
    t.integer "text_filter_id"
    t.text "whiteboard"
    t.integer "article_id"
    t.string "email", limit: 255
    t.string "url", limit: 255
    t.string "ip", limit: 40
    t.string "blog_name", limit: 255
    t.boolean "published", default: false
    t.integer "blog_id", null: false
    t.datetime "published_at", precision: nil
    t.text "state"
    t.boolean "status_confirmed"
    t.index ["article_id"], name: "index_feedback_on_article_id"
    t.index ["text_filter_id"], name: "index_feedback_on_text_filter_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "content_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "page_caches", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.index ["name"], name: "page_caches_name_index"
  end

  create_table "pings", id: :serial, force: :cascade do |t|
    t.integer "article_id"
    t.string "url", limit: 255
    t.datetime "created_at", precision: nil
    t.index ["article_id"], name: "pings_article_id_index"
  end

  create_table "redirects", id: :serial, force: :cascade do |t|
    t.string "from_path", limit: 255
    t.string "to_path", limit: 255
  end

  create_table "resources", id: :serial, force: :cascade do |t|
    t.integer "size"
    t.string "filename", limit: 255
    t.string "mime", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "article_id"
    t.boolean "itunes_metadata"
    t.string "itunes_author", limit: 255
    t.string "itunes_subtitle", limit: 255
    t.integer "itunes_duration"
    t.text "itunes_summary"
    t.string "itunes_keywords", limit: 255
    t.string "itunes_category", limit: 255
    t.boolean "itunes_explicit"
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.string "sessid", limit: 255
    t.text "data"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["sessid"], name: "sessions_sessid_index"
  end

  create_table "sidebars", id: :serial, force: :cascade do |t|
    t.integer "active_position"
    t.text "config"
    t.integer "staged_position"
    t.string "type", limit: 255
    t.integer "blog_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "display_name", limit: 255
  end

  create_table "text_filters", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "description", limit: 255
    t.string "markup", limit: 255
    t.text "filters"
    t.text "params"
  end

  create_table "triggers", id: :serial, force: :cascade do |t|
    t.integer "pending_item_id"
    t.string "pending_item_type", limit: 255
    t.datetime "due_at", precision: nil
    t.string "trigger_method", limit: 255
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "login", limit: 255
    t.string "password", limit: 255
    t.text "email"
    t.text "name"
    t.boolean "notify_via_email"
    t.boolean "notify_on_new_articles"
    t.boolean "notify_on_comments"
    t.boolean "notify_watch_my_articles"
    t.boolean "notify_via_jabber"
    t.string "jabber", limit: 255
  end
end
