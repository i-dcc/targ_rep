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
  { :name => 'mirKO' },
  { :name => 'Sanger MGP' }
])

qc_field_descriptions = QcFieldDescription.create([
  {
    :qc_field    => 'production_qc_five_prime_screen',
    :description => "LR-PCR (and sometimes sequencing) test between the selection cassette and beyond the 5' homology arm.",
    :url         => 'http://www.knockoutmouse.org/kb/entry/78/'
  },
  {
    :qc_field    => 'production_qc_three_prime_screen',
    :description => "LR-PCR (and sometimes sequencing) test between the selection cassette and beyond the 3' homology arm.",
    :url         => 'http://www.knockoutmouse.org/kb/entry/78/'
  },
  {
    :qc_field    => 'production_qc_loxp_screen',
    :description => "LR-PCR (and sometimes sequencing) test between the 3' arm of the targeting cassette and the downstream LoxP",
    :url         => 'http://www.knockoutmouse.org/kb/entry/78/'
  }
  # ,
  # {
  #   :qc_field    => 'production_qc_loss_of_allele',
  #   :description => "",
  #   :url         => ''
  # },
  # {
  #   :qc_field    => 'production_qc_vector_integrity',
  #   :description => "",
  #   :url         => ''
  # }
])

Centre.create([
  { :id => 1, :name => 'WTSI' },
  { :id => 2, :name => 'KOMP' },
  { :id => 3, :name => 'EUCOMM' }
])
