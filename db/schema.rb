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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130524144132) do

  create_table "evaluations", :force => true do |t|
    t.integer  "suite_id"
    t.string   "name"
    t.integer  "max_result"
    t.integer  "red_below"
    t.integer  "green_above"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "stanine1"
    t.integer  "stanine2"
    t.integer  "stanine3"
    t.integer  "stanine4"
    t.integer  "stanine5"
    t.integer  "stanine6"
    t.integer  "stanine7"
    t.integer  "stanine8"
    t.date     "date"
    t.integer  "template_id"
    t.string   "description", :limit => 1024
  end

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "groups_students", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "student_id"
  end

  add_index "groups_students", ["group_id", "student_id"], :name => "index_groups_students_on_group_id_and_student_id"

  create_table "meetings", :force => true do |t|
    t.integer  "suite_id"
    t.string   "name"
    t.date     "date"
    t.boolean  "completed",  :default => false
    t.text     "notes"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.text     "agenda"
  end

  create_table "participants", :force => true do |t|
    t.integer  "suite_id"
    t.integer  "student_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "group_id"
  end

  create_table "rails_admin_histories", :force => true do |t|
    t.text     "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      :limit => 2
    t.integer  "year",       :limit => 8
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], :name => "index_rails_admin_histories"

  create_table "results", :force => true do |t|
    t.integer  "evaluation_id"
    t.integer  "student_id"
    t.integer  "value"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "color"
    t.integer  "stanine"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], :name => "index_roles_on_name_and_resource_type_and_resource_id"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "students", :force => true do |t|
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "personal_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "gender"
    t.text     "data"
  end

  create_table "suites", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "is_template", :default => false
    t.integer  "template_id"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       :limit => 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "name"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "users_roles", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], :name => "index_users_roles_on_user_id_and_role_id"

end
