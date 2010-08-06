
# This initializer is used to store the config for the available 
# options for the ESCell QC metrics in a single location...

qc_metrics = {
  :production_qc_five_prime_screen => ["pass","fail","no reads detected","not attempted"],
  :production_qc_three_prime_screen => ["pass","fail","no reads detected"],
  :production_qc_loxp_screen => ["pass","fail","no reads detected"],
  
  :user_qc_karyotype     => ["pass","fail","limit"],
  :user_qc_southern_blot => ["pass","fail 5' end","fail 3' end","fail both ends","double integration"]
}

pass_fail_only_qc_fields = [
  :production_qc_loss_of_allele,
  :production_qc_vector_integrity,
  
  :distribution_qc_copy_number,
  :distribution_qc_five_prime_sr_pcr,
  :distribution_qc_three_prime_sr_pcr,
  
  :user_qc_five_prime_lr_pcr,
  :user_qc_three_prime_lr_pcr,
  :user_qc_map_test,
  :user_qc_tv_backbone_assay,
  :user_qc_loxp_confirmation,
  :user_qc_loss_of_wt_allele,
  :user_qc_neo_count_qpcr,
  :user_qc_lacz_sr_pcr,
  :user_qc_mutant_specific_sr_pcr,
  :user_qc_five_prime_cassette_integrity,
  :user_qc_neo_sr_pcr
]

pass_fail_only_qc_fields.each do |field|
  qc_metrics[field] = ["pass","fail"]
end

ESCELL_QC_OPTIONS = qc_metrics.clone