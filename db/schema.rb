# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150418165101) do

  create_table "feeds", force: :cascade do |t|
    t.string  "title",         limit: 255,                   null: false
    t.string  "name",          limit: 255,                   null: false
    t.string  "url",           limit: 255,                   null: false
    t.boolean "public_stats",  limit: 1,     default: false, null: false
    t.boolean "public_counts", limit: 1,     default: false, null: false
    t.text    "contents",      limit: 65535
    t.string  "last_version",  limit: 255
    t.string  "load_error",    limit: 255
  end

  create_table "options", force: :cascade do |t|
    t.integer "property_id", limit: 4,   null: false
    t.string  "name",        limit: 255, null: false
  end

  create_table "properties", force: :cascade do |t|
    t.string "name", limit: 255, null: false
  end

  create_table "statistics", force: :cascade do |t|
    t.integer "feed_id",     limit: 4,             null: false
    t.integer "year",        limit: 4,             null: false
    t.integer "month",       limit: 4,             null: false
    t.integer "property_id", limit: 4,             null: false
    t.integer "option_id",   limit: 4,             null: false
    t.integer "counter",     limit: 4, default: 0, null: false
  end

  add_index "statistics", ["feed_id", "year", "month", "property_id", "option_id"], name: "stats_index", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string "password_digest", limit: 255
  end

end
