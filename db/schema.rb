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

ActiveRecord::Schema.define(:version => 20100118090008) do

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "changes"
    t.integer  "version",        :default => 0
    t.datetime "created_at"
  end

  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"

  create_table "es_cells", :force => true do |t|
    t.integer  "molecular_structure_id",    :null => false
    t.integer  "targeting_vector_id"
    t.string   "parental_cell_line"
    t.string   "allele_symbol_superscript"
    t.string   "name",                      :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "comment"
    t.string   "contact"
    t.string   "upper_LR_check"
    t.string   "upper_SR_check"
    t.string   "lower_LR_check"
    t.string   "lower_SR_check"
  end

  add_index "es_cells", ["molecular_structure_id"], :name => "molecular_structure_id"
  add_index "es_cells", ["targeting_vector_id"], :name => "targeting_vector_id"

  create_table "genbank_files", :force => true do |t|
    t.integer  "molecular_structure_id", :null => false
    t.text     "escell_clone"
    t.text     "targeting_vector"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "genbank_files", ["molecular_structure_id"], :name => "molecular_structure_id"

  create_table "molecular_structures", :force => true do |t|
    t.string   "assembly",            :default => "NCBIM37", :null => false
    t.string   "chromosome",                                 :null => false
    t.string   "strand",                                     :null => false
    t.string   "mgi_accession_id",                           :null => false
    t.integer  "homology_arm_start",                         :null => false
    t.integer  "homology_arm_end",                           :null => false
    t.integer  "loxp_start"
    t.integer  "loxp_end"
    t.integer  "cassette_start"
    t.integer  "cassette_end"
    t.string   "cassette"
    t.string   "backbone"
    t.string   "design_type",                                :null => false
    t.string   "design_subtype"
    t.string   "subtype_description"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "molecular_structures", ["assembly", "chromosome", "strand", "homology_arm_start", "homology_arm_end", "cassette_start", "cassette_end", "loxp_start", "loxp_end", "cassette", "backbone"], :name => "index_mol_struct", :unique => true

  create_table "pipelines", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "targeting_vectors", :force => true do |t|
    t.integer  "pipeline_id",            :null => false
    t.integer  "molecular_structure_id", :null => false
    t.string   "ikmc_project_id"
    t.string   "name",                   :null => false
    t.string   "intermediate_vector"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "targeting_vectors", ["molecular_structure_id"], :name => "molecular_structure_id"
  add_index "targeting_vectors", ["pipeline_id", "name"], :name => "index_targvec", :unique => true

  create_table "users", :force => true do |t|
    t.string   "username",                             :null => false
    t.string   "email"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "last_login_at"
    t.boolean  "is_admin",          :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "es_cells", "molecular_structures", :name => "es_cells_ibfk_1", :dependent => :delete
  add_foreign_key "es_cells", "targeting_vectors", :name => "es_cells_ibfk_2", :dependent => :delete

  add_foreign_key "genbank_files", "molecular_structures", :name => "genbank_files_ibfk_1", :dependent => :delete

  add_foreign_key "targeting_vectors", "molecular_structures", :name => "targeting_vectors_ibfk_2", :dependent => :delete
  add_foreign_key "targeting_vectors", "pipelines", :name => "targeting_vectors_ibfk_1", :dependent => :delete

end
