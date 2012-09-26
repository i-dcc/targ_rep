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

  # you would think it could do should validate_inclusion_of, but no
  # and I can't work out how to do a loop either

  #should allow_value('pass').for(:five_prime_sr_pcr)
  #should allow_value('fail').for(:five_prime_sr_pcr)
  #should allow_value('pass').for(:three_prime_sr_pcr)
  #should allow_value('fail').for(:three_prime_sr_pcr)
  #should allow_value('pass').for(:copy_number)
  #should allow_value('fail').for(:copy_number)
  #should allow_value('pass').for(:five_prime_lr_pcr)
  #should allow_value('fail').for(:five_prime_lr_pcr)
  #should allow_value('pass').for(:three_prime_lr_pcr)
  #should allow_value('fail').for(:three_prime_lr_pcr)
  #should allow_value('pass').for(:thawing)
  #should allow_value('fail').for(:thawing)
  #should allow_value('pass').for(:loa)
  #should allow_value('passb').for(:loa)
  #should allow_value('fail').for(:loa)
  #should allow_value('pass').for(:loxp)
  #should allow_value('passb').for(:loxp)
  #should allow_value('fail').for(:loxp)
  #should allow_value('passb').for(:lacz)
  #should allow_value('pass').for(:lacz)
  #should allow_value('fail').for(:lacz)
  #should allow_value('pass').for(:chr1)
  #should allow_value('passb').for(:chr1)
  #should allow_value('fail').for(:chr1)
  #should allow_value('pass').for(:chr8a)
  #should allow_value('passb').for(:chr8a)
  #should allow_value('fail').for(:chr8a)
  #should allow_value('pass').for(:chr8b)
  #should allow_value('fail').for(:chr8b)
  #should allow_value('pass').for(:chr11a)
  #should allow_value('passb').for(:chr11a)
  #should allow_value('fail').for(:chr11a)
  #should allow_value('pass').for(:chr11b)
  #should allow_value('passb').for(:chr11b)
  #should allow_value('fail').for(:chr11b)
  #should allow_value('pass').for(:chry)
  #should allow_value('passb').for(:chry)
  #should allow_value('fail').for(:chry)

end
