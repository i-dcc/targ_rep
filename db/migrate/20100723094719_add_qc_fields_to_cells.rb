class AddQcFieldsToCells < ActiveRecord::Migration
  def self.up
    add_column :es_cells, :qc_map_test, :string
    add_column :es_cells, :qc_karyotype, :string
    add_column :es_cells, :qc_tv_backbone_assay, :string
    add_column :es_cells, :qc_loxp_confirmation, :string
    add_column :es_cells, :qc_southern_blot, :string
    add_column :es_cells, :qc_loss_of_wt_allele, :string
    add_column :es_cells, :qc_neo_count_qpcr, :string
    add_column :es_cells, :qc_lacz_sr_pcr, :string
    add_column :es_cells, :qc_mutant_specific_sr_pcr, :string
    add_column :es_cells, :qc_five_prime_cassette_integrity, :string
    add_column :es_cells, :qc_neo_sr_pcr, :string
    add_column :es_cells, :qc_comment, :text
    
    rename_column :es_cells, :upper_LR_check, :qc_five_prime_lr_pcr
    rename_column :es_cells, :lower_LR_check, :qc_three_prime_lr_pcr
    
    remove_column :es_cells, :upper_SR_check
    remove_column :es_cells, :lower_SR_check
        
    create_table :qc_field_descriptions, :force => true do |t|
      t.column :qc_field, :string, :null => false
      t.column :description, :text, :null => false
      t.column :url, :string
    end
    add_index :qc_field_descriptions, [:qc_field], :unique => true
  end

  def self.down
    remove_index :qc_field_descriptions, :column => [:qc_field]
    drop_table :qc_field_descriptions
    
    add_column :es_cells, :lower_SR_check, :string
    add_column :es_cells, :upper_SR_check, :string
    
    rename_column :es_cells, :qc_three_prime_lr_pcr, :lower_LR_check
    rename_column :es_cells, :qc_five_prime_lr_pcr, :upper_LR_check
    
    remove_column :es_cells, :qc_comment
    remove_column :es_cells, :qc_neo_sr_pcr
    remove_column :es_cells, :qc_five_prime_cassette_integrity
    remove_column :es_cells, :qc_mutant_specific_sr_pcr
    remove_column :es_cells, :qc_lacz_sr_pcr
    remove_column :es_cells, :qc_neo_count_qpcr
    remove_column :es_cells, :qc_loss_of_wt_allele
    remove_column :es_cells, :qc_southern_blot
    remove_column :es_cells, :qc_loxp_confirmation
    remove_column :es_cells, :qc_tv_backbone_assay
    remove_column :es_cells, :qc_karyotype
    remove_column :es_cells, :qc_map_test
  end
end