require 'test_helper'

class DistributionQcTest < ActiveSupport::TestCase

  should belong_to(:es_cell)
  should belong_to(:centre)

  should validate_numericality_of :karyotype_low
  should validate_numericality_of :karyotype_high

  should have_db_column(:five_prime_sr_pcr).of_type(:string)
  should have_db_column(:three_prime_sr_pcr).of_type(:string)
  should have_db_column(:karyotype_low).of_type(:float)
  should have_db_column(:karyotype_high).of_type(:float)
  should have_db_column(:copy_number).of_type(:string)
  should have_db_column(:five_prime_lr_pcr).of_type(:string)
  should have_db_column(:three_prime_lr_pcr).of_type(:string)
  should have_db_column(:thawing).of_type(:string)
  should have_db_column(:loa).of_type(:string)
  should have_db_column(:loxp).of_type(:string)
  should have_db_column(:lacz).of_type(:string)
  should have_db_column(:chr1).of_type(:string)
  should have_db_column(:chr8a).of_type(:string)
  should have_db_column(:chr8b).of_type(:string)
  should have_db_column(:chr11a).of_type(:string)
  should have_db_column(:chr11b).of_type(:string)
  should have_db_column(:chry).of_type(:string)
  should have_db_column(:es_cell_id).of_type(:integer)
  should have_db_column(:centre_id).of_type(:integer)

  should 'test centre_name'

end
