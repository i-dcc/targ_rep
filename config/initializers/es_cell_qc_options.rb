
# This initializer is used to store the config for the available 
# options for the ESCell QC metrics in a single location...

qc_metrics = {
  :qc_karyotype     => ["pass","fail","limit"],
  :qc_southern_blot => ["pass","fail 5' end","fail 3' end","fail both ends","double integration"]
}

pass_fail_only_qc_fields = [
  :qc_five_prime_lr_pcr,
  :qc_three_prime_lr_pcr,
  :qc_map_test,
  :qc_tv_backbone_assay,
  :qc_loxp_confirmation,
  :qc_loss_of_wt_allele,
  :qc_neo_count_qpcr,
  :qc_lacz_sr_pcr,
  :qc_mutant_specific_sr_pcr,
  :qc_five_prime_cassette_integrity,
  :qc_neo_sr_pcr
]

pass_fail_only_qc_fields.each do |field|
  qc_metrics[field] = ["pass","fail"]
end

ESCELL_QC_OPTIONS = qc_metrics.clone