class AddQcFieldsToCells < ActiveRecord::Migration
  def self.up
    ##
    ## 'user' qc fields
    ##
    
    add_column :es_cells, :user_qc_map_test, :string
    add_column :es_cells, :user_qc_karyotype, :string
    add_column :es_cells, :user_qc_tv_backbone_assay, :string
    add_column :es_cells, :user_qc_loxp_confirmation, :string
    add_column :es_cells, :user_qc_southern_blot, :string
    add_column :es_cells, :user_qc_loss_of_wt_allele, :string
    add_column :es_cells, :user_qc_neo_count_qpcr, :string
    add_column :es_cells, :user_qc_lacz_sr_pcr, :string
    add_column :es_cells, :user_qc_mutant_specific_sr_pcr, :string
    add_column :es_cells, :user_qc_five_prime_cassette_integrity, :string
    add_column :es_cells, :user_qc_neo_sr_pcr, :string
    add_column :es_cells, :user_qc_five_prime_lr_pcr, :string
    add_column :es_cells, :user_qc_three_prime_lr_pcr, :string
    add_column :es_cells, :user_qc_comment, :text
    
    ##
    ## 'production' (centre) qc fields
    ##
    
    rename_column :es_cells, :upper_LR_check, :production_qc_five_prime_screen
    rename_column :es_cells, :lower_LR_check, :production_qc_three_prime_screen
    
    add_column :es_cells, :production_qc_loxp_screen, :string
    add_column :es_cells, :production_qc_loss_of_allele, :string
    add_column :es_cells, :production_qc_vector_integrity, :string
    
    execute "update es_cells set production_qc_five_prime_screen = 'pass' where production_qc_five_prime_screen = 'Passed'"
    execute "update es_cells set production_qc_five_prime_screen = 'fail' where production_qc_five_prime_screen = 'Failed'"
    execute "update es_cells set production_qc_three_prime_screen = 'pass' where production_qc_three_prime_screen = 'Passed'"
    execute "update es_cells set production_qc_three_prime_screen = 'fail' where production_qc_three_prime_screen = 'Failed'"
    
    ##
    ## 'distribution'(centre) qc fields
    ##
    
    add_column :es_cells, :distribution_qc_karyotype_low, :float
    add_column :es_cells, :distribution_qc_karyotype_high, :float
    add_column :es_cells, :distribution_qc_copy_number, :string
    rename_column :es_cells, :upper_SR_check, :distribution_qc_five_prime_sr_pcr
    rename_column :es_cells, :lower_SR_check, :distribution_qc_three_prime_sr_pcr
  end

  def self.down
    rename_column :es_cells, :distribution_qc_three_prime_sr_pcr, :lower_SR_check
    rename_column :es_cells, :distribution_qc_five_prime_sr_pcr, :upper_SR_check
    remove_column :es_cells, :distribution_qc_copy_number
    remove_column :es_cells, :distribution_qc_karyotype_high
    remove_column :es_cells, :distribution_qc_karyotype_low
    
    execute "update es_cells set production_qc_five_prime_screen = 'Passed' where production_qc_five_prime_screen = 'pass'"
    execute "update es_cells set production_qc_five_prime_screen = 'Failed' where production_qc_five_prime_screen = 'fail'"
    execute "update es_cells set production_qc_three_prime_screen = 'Passed' where production_qc_three_prime_screen = 'pass'"
    execute "update es_cells set production_qc_three_prime_screen = 'Failed' where production_qc_three_prime_screen = 'fail'"
    
    remove_column :es_cells, :production_qc_vector_integrity
    remove_column :es_cells, :production_qc_loss_of_allele
    remove_column :es_cells, :production_qc_loxp_screen
    
    rename_column :es_cells, :production_qc_three_prime_screen, :lower_LR_check
    rename_column :es_cells, :production_qc_five_prime_screen, :upper_LR_check
    
    remove_column :es_cells, :user_qc_comment
    remove_column :es_cells, :user_qc_three_prime_lr_pcr
    remove_column :es_cells, :user_qc_five_prime_lr_pcr
    remove_column :es_cells, :user_qc_neo_sr_pcr
    remove_column :es_cells, :user_qc_five_prime_cassette_integrity
    remove_column :es_cells, :user_qc_mutant_specific_sr_pcr
    remove_column :es_cells, :user_qc_lacz_sr_pcr
    remove_column :es_cells, :user_qc_neo_count_qpcr
    remove_column :es_cells, :user_qc_loss_of_wt_allele
    remove_column :es_cells, :user_qc_southern_blot
    remove_column :es_cells, :user_qc_loxp_confirmation
    remove_column :es_cells, :user_qc_tv_backbone_assay
    remove_column :es_cells, :user_qc_karyotype
    remove_column :es_cells, :user_qc_map_test
  end
end