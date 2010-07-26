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
    
    execute "update es_cells set qc_five_prime_lr_pcr = 'pass' where qc_five_prime_lr_pcr = 'Passed'"
    execute "update es_cells set qc_five_prime_lr_pcr = 'fail' where qc_five_prime_lr_pcr = 'Failed'"
    execute "update es_cells set qc_three_prime_lr_pcr = 'pass' where qc_three_prime_lr_pcr = 'Passed'"
    execute "update es_cells set qc_three_prime_lr_pcr = 'fail' where qc_three_prime_lr_pcr = 'Failed'"
    
    remove_column :es_cells, :upper_SR_check
    remove_column :es_cells, :lower_SR_check
  end

  def self.down
    add_column :es_cells, :lower_SR_check, :string
    add_column :es_cells, :upper_SR_check, :string
    
    execute "update es_cells set qc_five_prime_lr_pcr = 'Passed' where qc_five_prime_lr_pcr = 'pass'"
    execute "update es_cells set qc_five_prime_lr_pcr = 'Failed' where qc_five_prime_lr_pcr = 'fail'"
    execute "update es_cells set qc_three_prime_lr_pcr = 'Passed' where qc_three_prime_lr_pcr = 'pass'"
    execute "update es_cells set qc_three_prime_lr_pcr = 'Failed' where qc_three_prime_lr_pcr = 'fail'"
    
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