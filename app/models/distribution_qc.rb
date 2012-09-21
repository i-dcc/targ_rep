class DistributionQc < ActiveRecord::Base
  belongs_to :es_cell
  belongs_to :centre

  validates_numericality_of :karyotype_low,
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to    => 1,
    :allow_nil                => true

  validates_numericality_of :karyotype_high,
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to    => 1,
    :allow_nil                => true

end

# == Schema Information
#
# Table name: distribution_qcs
#
#  id                 :integer(4)      not null, primary key
#  five_prime_sr_pcr  :string(255)
#  three_prime_sr_pcr :string(255)
#  karyotype_low      :float
#  karyotype_high     :float
#  copy_number        :string(255)
#  five_prime_lr_pcr  :string(255)
#  three_prime_lr_pcr :string(255)
#  thawing            :string(255)
#  loa                :string(255)
#  loxp               :string(255)
#  lacz               :string(255)
#  chr1               :string(255)
#  chr8a              :string(255)
#  chr8b              :string(255)
#  chr11a             :string(255)
#  chr11b             :string(255)
#  chry               :string(255)
#  es_cell_id         :integer(4)
#  centre_id          :integer(4)
#  created_at         :datetime
#  updated_at         :datetime
#

