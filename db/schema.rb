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

ActiveRecord::Schema.define(:version => 20131002062258) do

  create_table "activities", :force => true do |t|
    t.integer  "suite_id"
    t.integer  "meeting_id"
    t.string   "type"
    t.string   "status"
    t.string   "name"
    t.text     "description"
    t.text     "notes"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.date     "end_date"
    t.date     "start_date"
  end

  create_table "activities_groups", :id => false, :force => true do |t|
    t.integer "activity_id"
    t.integer "group_id"
  end

  add_index "activities_groups", ["activity_id", "group_id"], :name => "index_activities_groups_on_activity_id_and_group_id"

  create_table "activities_students", :id => false, :force => true do |t|
    t.integer "activity_id"
    t.integer "student_id"
  end

  add_index "activities_students", ["activity_id", "student_id"], :name => "index_activities_students_on_activity_id_and_student_id"

  create_table "activities_users", :id => false, :force => true do |t|
    t.integer "activity_id"
    t.integer "user_id"
  end

  add_index "activities_users", ["activity_id", "user_id"], :name => "index_activities_users_on_activity_id_and_user_id"

  create_table "evaluations", :force => true do |t|
    t.integer  "suite_id"
    t.string   "name"
    t.integer  "max_result"
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
    t.date     "date"
    t.integer  "template_id"
    t.string   "description",   :limit => 1024
    t.string   "type",                          :default => "template"
    t.string   "target",                        :default => "all"
    t.text     "value_aliases"
    t.string   "value_type",                    :default => "numeric"
    t.text     "colors"
    t.text     "stanines"
    t.string   "status",                        :default => "empty"
    t.integer  "instance_id"
  end

  add_index "evaluations", ["status"], :name => "index_evaluations_on_status"

  create_table "evaluations_participants", :id => false, :force => true do |t|
    t.integer "evaluation_id"
    t.integer "participant_id"
  end

  add_index "evaluations_participants", ["evaluation_id", "participant_id"], :name => "index_evaluations_participants_on_ids"

  create_table "evaluations_users", :id => false, :force => true do |t|
    t.integer "evaluation_id"
    t.integer "user_id"
  end

  add_index "evaluations_users", ["evaluation_id", "user_id"], :name => "index_evaluations_users_on_ids"

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "imported",    :default => false
    t.integer  "instance_id"
  end

  create_table "groups_students", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "student_id"
  end

  add_index "groups_students", ["group_id", "student_id"], :name => "index_groups_students_on_group_id_and_student_id"

  create_table "groups_users", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "user_id"
  end

  add_index "groups_users", ["group_id", "user_id"], :name => "index_groups_users_on_group_id_and_user_id"

  create_table "instances", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "instructions", :force => true do |t|
    t.string   "title"
    t.string   "for_page"
    t.text     "film"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.text     "description"
  end

  add_index "instructions", ["for_page"], :name => "index_instructions_on_for_page"

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
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.string   "color"
    t.integer  "stanine"
    t.boolean  "absent",        :default => false
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

  create_table "settings", :force => true do |t|
    t.text     "data"
    t.integer  "customizer_id"
    t.string   "customizer_type"
    t.integer  "customizable_id"
    t.string   "customizable_type"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "students", :force => true do |t|
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "personal_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "gender"
    t.text     "data"
    t.integer  "instance_id"
  end

  create_table "suites", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
    t.boolean  "is_template",                         :default => false
    t.integer  "template_id"
    t.string   "generic_evaluations", :limit => 1024
    t.string   "student_data",        :limit => 1024
    t.integer  "instance_id"
  end

  create_table "table_states", :force => true do |t|
    t.string   "name"
    t.text     "data"
    t.integer  "base_id"
    t.string   "base_type"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
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
    t.string   "email",                  :default => "",    :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "name"
    t.boolean  "use_yubikey",            :default => true
    t.string   "registered_yubikey"
    t.integer  "active_instance_id"
    t.boolean  "invisible",              :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "users_roles", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], :name => "index_users_roles_on_user_id_and_role_id"

end
