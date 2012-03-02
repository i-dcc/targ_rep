
# This initializer is used to store the config for the available
# options for the ESCell QC metrics in a single location...

qc_metrics = {
  "production_qc_five_prime_screen"       => { :name => "5' Screen",   :values => ["pass","not confirmed","no reads detected","not attempted"] },
  "production_qc_three_prime_screen"      => { :name => "3' Screen",   :values => ["pass","not confirmed","no reads detected"] },
  "production_qc_loxp_screen"             => { :name => "LoxP Screen", :values => ["pass","not confirmed","no reads detected"] },
  "production_qc_loss_of_allele"          => { :name => "Loss of WT Allele (LOA)" },
  "production_qc_vector_integrity"        => { :name => "Vector Integrity" },

  "distribution_qc_copy_number"           => { :name => "Copy Number" },
  "distribution_qc_five_prime_lr_pcr"     => { :name => "5' LR-PCR" },
  "distribution_qc_three_prime_lr_pcr"    => { :name => "3' LR-PCR" },
  "distribution_qc_five_prime_sr_pcr"     => { :name => "5' SR-PCR" },
  "distribution_qc_three_prime_sr_pcr"    => { :name => "3' SR-PCR" },
  "distribution_qc_thawing"               => { :name => "Cells Thawed Correctly" },

  "user_qc_karyotype"                     => { :name => "Karyotype",     :values => ["pass","fail","limit"] },
  "user_qc_southern_blot"                 => { :name => "Southern Blot", :values => ["pass","fail 5' end","fail 3' end","fail both ends","double integration"] },
  "user_qc_five_prime_lr_pcr"             => { :name => "5' LR-PCR" },
  "user_qc_three_prime_lr_pcr"            => { :name => "3' LR-PCR" },
  "user_qc_map_test"                      => { :name => "Map Test" },
  "user_qc_tv_backbone_assay"             => { :name => "TV Backbone Assay" },
  "user_qc_loxp_confirmation"             => { :name => "LoxP Confirmation" },
  "user_qc_loss_of_wt_allele"             => { :name => "Loss of WT Allele (LOA)" },
  "user_qc_neo_count_qpcr"                => { :name => "Neo Count (qPCR)" },
  "user_qc_lacz_sr_pcr"                   => { :name => "LacZ SR-PCR" },
  "user_qc_mutant_specific_sr_pcr"        => { :name => "Mutant Specific SR-PCR" },
  "user_qc_five_prime_cassette_integrity" => { :name => "5' Cassette Integrity" },
  "user_qc_neo_sr_pcr"                    => { :name => "Neo SR-PCR" },

  "distribution_qc_loa"                      => { :name => "LOA",             :values => ["pass","fail"] },
  "distribution_qc_loxp"                     => { :name => "LOXP",            :values => ["pass","fail"] },
  "distribution_qc_lacz"                     => { :name => "LACZ",            :values => ["pass","fail"] },
  "distribution_qc_chr1"                     => { :name => "Chromosome 1",    :values => ["pass","fail"] },
  "distribution_qc_chr8a"                    => { :name => "Chromosome 8a",   :values => ["pass","fail"] },
  "distribution_qc_chr8b"                    => { :name => "Chromosome 8b",   :values => ["pass","fail"] },
  "distribution_qc_chr11a"                   => { :name => "Chromosome 11a",  :values => ["pass","fail"] },
  "distribution_qc_chr11b"                   => { :name => "Chromosome 11b",  :values => ["pass","fail"] },
  "distribution_qc_chry"                     => { :name => "Chromosome Y",    :values => ["pass","fail"] }
}

qc_metrics.each do |field,data|
  if data[:values].nil?
    qc_metrics[field][:values] = ['pass','fail']
  end
end

ESCELL_QC_OPTIONS = qc_metrics.clone

##
## Now setup the conflict select options
##

user_qc_fields  = []
user_qc_options = []
user_qc_conf    = ESCELL_QC_OPTIONS.clone
user_qc_conf.delete_if{ |qc_field,data| !qc_field.match(/^user/) }
ordered_keys    = user_qc_conf.keys.sort{ |a,b| user_qc_conf[a][:name] <=> user_qc_conf[b][:name] }

ordered_keys.each do |field|
  conf = user_qc_conf[field]
  user_qc_fields.push([ conf[:name], field ])
  conf[:values].each{ |qc_value| user_qc_options.push( qc_value ) }
end

user_qc_options.uniq!

ESCELL_QC_CONFLICT_FIELDS  = user_qc_fields
ESCELL_QC_CONFLICT_OPTIONS = user_qc_options
