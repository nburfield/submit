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

ActiveRecord::Schema.define(version: 20170117212826) do

  create_table "assignments", force: true do |t|
    t.boolean  "lock"
    t.datetime "due_date"
    t.datetime "start_date"
    t.text     "description"
    t.integer  "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.float    "total_grade", limit: 24
  end

  add_index "assignments", ["course_id"], name: "index_assignments_on_course_id", using: :btree

  create_table "comments", force: true do |t|
    t.text     "contents"
    t.integer  "line"
    t.integer  "upload_datum_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["upload_datum_id"], name: "index_comments_on_upload_datum_id", using: :btree

  create_table "compile_saves", force: true do |t|
    t.integer "submission_id"
    t.text    "output"
    t.string  "run_method_name"
  end

  add_index "compile_saves", ["submission_id"], name: "index_compile_saves_on_submission_id", using: :btree

  create_table "courses", force: true do |t|
    t.string   "name"
    t.boolean  "open"
    t.text     "description"
    t.string   "join_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "year"
    t.string   "term"
  end

  create_table "courses_users", id: false, force: true do |t|
    t.integer "course_id"
    t.integer "user_id"
  end

  create_table "create_classes", force: true do |t|
    t.string   "name"
    t.boolean  "open"
    t.string   "semester"
    t.text     "description"
    t.string   "join_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "inputs", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.text     "data"
    t.binary   "output"
    t.boolean  "student_visible"
    t.integer  "run_method_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "inputs", ["run_method_id"], name: "index_inputs_on_run_method_id", using: :btree

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "run_methods", force: true do |t|
    t.string   "name"
    t.string   "run_command"
    t.text     "description"
    t.integer  "test_case_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "run_methods", ["test_case_id"], name: "index_run_methods_on_test_case_id", using: :btree

  create_table "run_saves", force: true do |t|
    t.integer  "submission_id"
    t.binary   "difference"
    t.boolean  "pass"
    t.binary   "output"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "input_id"
  end

  add_index "run_saves", ["submission_id"], name: "index_run_saves_on_submission_id", using: :btree

  create_table "submissions", force: true do |t|
    t.float    "grade",         limit: 24
    t.text     "note"
    t.integer  "assignment_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "submitted",                default: false
    t.datetime "submit_time"
    t.string   "key"
  end

  add_index "submissions", ["assignment_id"], name: "index_submissions_on_assignment_id", using: :btree
  add_index "submissions", ["user_id"], name: "index_submissions_on_user_id", using: :btree

  create_table "test_cases", force: true do |t|
    t.integer  "assignment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cpu_time",      default: 10
    t.integer  "core_size",     default: 0
    t.string   "column_name"
    t.string   "key"
  end

  add_index "test_cases", ["assignment_id"], name: "index_test_cases_on_assignment_id", using: :btree

  create_table "upload_data", force: true do |t|
    t.string   "name"
    t.binary   "contents",      limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "submission_id"
    t.integer  "test_case_id"
    t.string   "file_type"
    t.boolean  "shared"
  end

  add_index "upload_data", ["submission_id"], name: "index_upload_data_on_submission_id", using: :btree
  add_index "upload_data", ["test_case_id"], name: "index_upload_data_on_test_case_id", using: :btree

  create_table "user_sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_sessions", ["session_id"], name: "index_user_sessions_on_session_id", using: :btree
  add_index "user_sessions", ["updated_at"], name: "index_user_sessions_on_updated_at", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                            null: false
    t.string   "persistence_token",                null: false
    t.string   "single_access_token",              null: false
    t.string   "perishable_token",                 null: false
    t.integer  "login_count",         default: 0,  null: false
    t.integer  "failed_login_count",  default: 0,  null: false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name",          default: ""
    t.string   "last_name",           default: ""
    t.string   "netid",               default: ""
  end

  create_table "users_roles", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

end
