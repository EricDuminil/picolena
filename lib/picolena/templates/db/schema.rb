# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090213234937) do

  create_table "documents", :force => true do |t|
    t.string   "probably_unique_id"
    t.string   "complete_path"
    t.string   "alias_path"
    t.string   "filename"
    t.string   "basename"
    t.string   "filetype"
    t.text     "cache_content"
    t.string   "language"
    t.datetime "modified"
  end

end
