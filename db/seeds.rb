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

mutation_methods = MutationMethod.create([
 { :id => 1, :name => 'Targeted mutation', :code => 'tgm' },
 { :id => 2, :name => 'Recombination mediated cassette exchange', :code=> 'rmce' }
])

mutation_types = MutationType.create([
 { :id => 1, :name => 'Conditional Ready', :code => 'crd' },
 { :id => 2, :name => 'Deletion', :code => 'del' },
 { :id => 3, :name => 'Targeted non-conditional', :code => 'tnc' },
 { :id => 4, :name => 'Cre knock-in', :code => 'cki' },
 { :id => 5, :name => 'Cre BAC', :code => 'cbc'}
])

mutation_sub_types = MutationSubtype.create([
 { :id => 1, :name => 'Domain disruption', :code => 'dmd' },
 { :id => 2, :name => 'Frameshift', :code => 'fms' },
 { :id => 3, :name => 'Artificial intron', :code => 'afi' },
 { :id => 4, :name => 'Hprt', :code => 'hpt'},
 { :id => 5, :name => 'Rosa26', :code => 'rsa' }
])
