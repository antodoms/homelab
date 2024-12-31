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

ActiveRecord::Schema[8.0].define(version: 2024_12_30_110048) do
  create_table "download_artifacts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "torrent_link"
    t.string "magnet_link"
    t.integer "movie_id", null: false
    t.integer "language_id"
    t.integer "quality_id", null: false
    t.index ["language_id"], name: "index_download_artifacts_on_language_id"
    t.index ["movie_id"], name: "index_download_artifacts_on_movie_id"
    t.index ["quality_id"], name: "index_download_artifacts_on_quality_id"
  end

  create_table "languages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
  end

  create_table "movie_languages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "movie_id", null: false
    t.integer "language_id", null: false
    t.index ["language_id"], name: "index_movie_languages_on_language_id"
    t.index ["movie_id"], name: "index_movie_languages_on_movie_id"
  end

  create_table "movie_qualities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "movie_id", null: false
    t.integer "quality_id", null: false
    t.index ["movie_id"], name: "index_movie_qualities_on_movie_id"
    t.index ["quality_id"], name: "index_movie_qualities_on_quality_id"
  end

  create_table "movies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "full_title"
    t.string "year"
    t.string "status"
    t.string "imdb_id"
    t.string "tmdb_id"
    t.string "poster_url"
    t.string "thread_url"
  end

  create_table "qualities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "download_artifacts", "languages"
  add_foreign_key "download_artifacts", "movies"
  add_foreign_key "download_artifacts", "qualities"
  add_foreign_key "movie_languages", "languages"
  add_foreign_key "movie_languages", "movies"
  add_foreign_key "movie_qualities", "movies"
  add_foreign_key "movie_qualities", "qualities"
end
