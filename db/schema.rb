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

ActiveRecord::Schema.define(:version => 20121016110744) do

  create_table "alleles", :force => true do |t|
    t.string   "assembly",            :limit => 50,  :default => "NCBIM37", :null => false
    t.string   "chromosome",          :limit => 2,                          :null => false
    t.string   "strand",              :limit => 1,                          :null => false
    t.string   "mgi_accession_id",    :limit => 50,                         :null => false
    t.integer  "homology_arm_start",                                        :null => false
    t.integer  "homology_arm_end",                                          :null => false
    t.integer  "loxp_start"
    t.integer  "loxp_end"
    t.integer  "cassette_start"
    t.integer  "cassette_end"
    t.string   "cassette",            :limit => 100
    t.string   "backbone",            :limit => 100
    t.string   "subtype_description"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "floxed_start_exon"
    t.string   "floxed_end_exon"
    t.integer  "project_design_id"
    t.string   "reporter"
    t.string   "cassette_type",       :limit => 50
    t.integer  "mutation_method_id"
    t.integer  "mutation_type_id"
    t.integer  "mutation_subtype_id"
  end

  add_index "alleles", ["mgi_accession_id", "project_design_id", "assembly", "chromosome", "strand", "homology_arm_start", "homology_arm_end", "cassette_start", "cassette_end", "loxp_start", "loxp_end", "cassette", "backbone"], :name => "index_mol_struct", :unique => true
  add_index "alleles", ["mgi_accession_id"], :name => "index_molecular_structures_on_mgi_accession_id"

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

  create_table "centres", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "distribution_qcs", :force => true do |t|
    t.string   "five_prime_sr_pcr"
    t.string   "three_prime_sr_pcr"
    t.float    "karyotype_low"
    t.float    "karyotype_high"
    t.string   "copy_number"
    t.string   "five_prime_lr_pcr"
    t.string   "three_prime_lr_pcr"
    t.string   "thawing"
    t.string   "loa"
    t.string   "loxp"
    t.string   "lacz"
    t.string   "chr1"
    t.string   "chr8a"
    t.string   "chr8b"
    t.string   "chr11a"
    t.string   "chr11b"
    t.string   "chry"
    t.integer  "es_cell_id"
    t.integer  "centre_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "distribution_qcs", ["centre_id", "es_cell_id"], :name => "index_distribution_qcs_centre_es_cell", :unique => true

  create_table "es_cell_qc_conflicts", :force => true do |t|
    t.integer  "es_cell_id"
    t.string   "qc_field",        :null => false
    t.string   "current_result",  :null => false
    t.string   "proposed_result", :null => false
    t.text     "comment"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "es_cell_qc_conflicts", ["es_cell_id"], :name => "es_cell_qc_conflicts_es_cell_id_fk"

  create_table "es_cells", :force => true do |t|
    t.integer  "allele_id",                                                             :null => false
    t.integer  "targeting_vector_id"
    t.string   "parental_cell_line"
    t.string   "allele_symbol_superscript"
    t.string   "name",                                                                  :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "comment"
    t.string   "contact"
    t.string   "production_qc_five_prime_screen"
    t.string   "distribution_qc_five_prime_sr_pcr"
    t.string   "production_qc_three_prime_screen"
    t.string   "distribution_qc_three_prime_sr_pcr"
    t.string   "ikmc_project_id"
    t.string   "user_qc_map_test"
    t.string   "user_qc_karyotype"
    t.string   "user_qc_tv_backbone_assay"
    t.string   "user_qc_loxp_confirmation"
    t.string   "user_qc_southern_blot"
    t.string   "user_qc_loss_of_wt_allele"
    t.string   "user_qc_neo_count_qpcr"
    t.string   "user_qc_lacz_sr_pcr"
    t.string   "user_qc_mutant_specific_sr_pcr"
    t.string   "user_qc_five_prime_cassette_integrity"
    t.string   "user_qc_neo_sr_pcr"
    t.string   "user_qc_five_prime_lr_pcr"
    t.string   "user_qc_three_prime_lr_pcr"
    t.text     "user_qc_comment"
    t.string   "production_qc_loxp_screen"
    t.string   "production_qc_loss_of_allele"
    t.string   "production_qc_vector_integrity"
    t.float    "distribution_qc_karyotype_low"
    t.float    "distribution_qc_karyotype_high"
    t.string   "distribution_qc_copy_number"
    t.string   "distribution_qc_five_prime_lr_pcr"
    t.string   "distribution_qc_three_prime_lr_pcr"
    t.string   "distribution_qc_thawing"
    t.string   "mgi_allele_id",                         :limit => 50
    t.integer  "pipeline_id"
    t.boolean  "report_to_public",                                    :default => true, :null => false
    t.string   "strain",                                :limit => 25
    t.string   "distribution_qc_loa",                   :limit => 4
    t.string   "distribution_qc_loxp",                  :limit => 4
    t.string   "distribution_qc_lacz",                  :limit => 4
    t.string   "distribution_qc_chr1",                  :limit => 4
    t.string   "distribution_qc_chr8a",                 :limit => 4
    t.string   "distribution_qc_chr8b",                 :limit => 4
    t.string   "distribution_qc_chr11a",                :limit => 4
    t.string   "distribution_qc_chr11b",                :limit => 4
    t.string   "distribution_qc_chry",                  :limit => 4
  end

  add_index "es_cells", ["allele_id"], :name => "es_cells_allele_id_fk"
  add_index "es_cells", ["name"], :name => "index_es_cells_on_name", :unique => true
  add_index "es_cells", ["pipeline_id"], :name => "es_cells_pipeline_id_fk"

  create_table "genbank_files", :force => true do |t|
    t.integer  "allele_id",                              :null => false
    t.text     "escell_clone",     :limit => 2147483647
    t.text     "targeting_vector", :limit => 2147483647
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
  end

  add_index "genbank_files", ["allele_id"], :name => "genbank_files_allele_id_fk"

  create_table "genbank_files_vw", :id => false, :force => true do |t|
    t.integer  "id",                          :default => 0,  :null => false
    t.integer  "allele_id",                                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "vector_gb_file", :limit => 3, :default => "", :null => false
    t.string   "allele_gb_file", :limit => 3, :default => "", :null => false
  end

  create_table "mutation_methods", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.string   "code",       :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mutation_subtypes", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.string   "code",       :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mutation_types", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.string   "code",       :limit => 100, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pipelines", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pipelines", ["name"], :name => "index_pipelines_on_name"

  create_table "qc_field_descriptions", :force => true do |t|
    t.string   "qc_field",    :null => false
    t.text     "description", :null => false
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "qc_field_descriptions", ["qc_field"], :name => "index_qc_field_descriptions_on_qc_field", :unique => true

  create_table "solr_update_queue_items", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "allele_id",               :null => false
    t.string   "action",     :limit => 0
  end

  add_index "solr_update_queue_items", ["allele_id"], :name => "index_solr_update_queue_items_on_allele_id", :unique => true

  create_table "targeting_vectors", :force => true do |t|
    t.integer  "allele_id",                             :null => false
    t.string   "ikmc_project_id"
    t.string   "name",                                  :null => false
    t.string   "intermediate_vector"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "report_to_public",    :default => true, :null => false
    t.integer  "pipeline_id"
  end

  add_index "targeting_vectors", ["allele_id"], :name => "targeting_vectors_allele_id_fk"
  add_index "targeting_vectors", ["name"], :name => "index_targvec", :unique => true
  add_index "targeting_vectors", ["pipeline_id"], :name => "targeting_vectors_pipeline_id_fk"

  create_table "users", :force => true do |t|
    t.string   "username",                              :null => false
    t.string   "email"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "last_login_at"
    t.boolean  "is_admin",           :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "login_count",        :default => 0,     :null => false
    t.integer  "failed_login_count", :default => 0,     :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.integer  "centre_id"
  end

  add_index "users", ["centre_id"], :name => "users_centre_id_fk"

  add_foreign_key "es_cell_qc_conflicts", "es_cells", :name => "es_cell_qc_conflicts_es_cell_id_fk", :dependent => :delete

  add_foreign_key "es_cells", "alleles", :name => "es_cells_allele_id_fk", :dependent => :delete
  add_foreign_key "es_cells", "pipelines", :name => "es_cells_pipeline_id_fk", :dependent => :delete

  add_foreign_key "genbank_files", "alleles", :name => "genbank_files_allele_id_fk", :dependent => :delete

  add_foreign_key "targeting_vectors", "alleles", :name => "targeting_vectors_allele_id_fk", :dependent => :delete
  add_foreign_key "targeting_vectors", "pipelines", :name => "targeting_vectors_pipeline_id_fk", :dependent => :delete

  add_foreign_key "users", "centres", :name => "users_centre_id_fk"

end
