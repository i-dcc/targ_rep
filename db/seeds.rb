# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

pipelines = Pipeline.create([
  { :name => 'KOMP-CSD' },
  { :name => 'KOMP-Regeneron' },
  { :name => 'NorCOMM' },
  { :name => 'EUCOMM' },
  { :name => 'mirKO' }
])

qc_field_descriptions = QcFieldDescriptions.create([
  {
    :qc_field    => 'qc_five_prime_lr_pcr',
    :description => "Long Range PCR (LR-PCR) test between the selection cassette and beyond the 5' homology arm.",
    :url         => ''
  },
  {
    :qc_field    => 'qc_three_prime_lr_pcr',
    :description => "Long Range PCR (LR-PCR) test between the selection cassette and beyond the 3' homology arm.",
    :url         => ''
  },
  {
    :qc_field    => 'qc_map_test',
    :description => "",
    :url         => ''
  },
  {
    :qc_field    => 'qc_karyotype',
    :description => "",
    :url         => ''
  },
  {
    :qc_field    => 'qc_tv_backbone_assay',
    :description => "",
    :url         => ''
  },
  {
    :qc_field    => 'qc_loxp_confirmation',
    :description => "",
    :url         => ''
  },
  {
    :qc_field    => 'qc_southern_blot',
    :description => "",
    :url         => ''
  },
  {
    :qc_field    => 'qc_loss_of_wt_allele',
    :description => "",
    :url         => ''
  },
  {
    :qc_field    => 'qc_neo_count_qpcr',
    :description => "",
    :url         => ''
  },
  {
    :qc_field    => 'qc_lacz_sr_pcr',
    :description => "",
    :url         => ''
  },
  {
    :qc_field    => 'qc_mutant_specific_sr_pcr',
    :description => "",
    :url         => ''
  },
  {
    :qc_field    => 'qc_five_prime_cassette_integrity',
    :description => "",
    :url         => ''
  },
  {
    :qc_field    => 'qc_neo_sr_pcr',
    :description => "",
    :url         => ''
  }
])