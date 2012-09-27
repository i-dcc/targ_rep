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

  should 'return centre_name' do
    name = 'Some Centre Name'
    centre = Centre.create( :name => name )
    dqc = DistributionQc.create( :centre => centre )
    assert_equal name, dqc.centre_name
  end

  short_values = %w( pass fail ) + [nil, '']
  long_values = short_values + ['passb']

  short_attributes = [
    :five_prime_sr_pcr,
    :three_prime_sr_pcr,
    :copy_number,
    :five_prime_lr_pcr,
    :three_prime_lr_pcr,
    :thawing
  ]

  long_attributes = [
    :loa,
    :loxp,
    :lacz,
    :chr1,
    :chr8a,
    :chr8b,
    :chr11a,
    :chr11b,
    :chry
  ]

  short_attributes.each do |attr|
    short_values.each do |value|
      should allow_value(value).for(attr)
    end
  end

  long_attributes.each do |attr|
    long_values.each do |value|
      should allow_value(value).for(attr)
    end
  end

  all_attributes = short_attributes + long_attributes

  all_attributes.each do |attr|
    should_not allow_value('nonsense').for(attr)
  end

end
