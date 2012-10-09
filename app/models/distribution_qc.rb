class DistributionQc < ActiveRecord::Base
  acts_as_audited

  extend AccessAssociationByAttribute

  attr_accessor :nested

  belongs_to :es_cell,        :class_name => 'EsCell',        :foreign_key => 'es_cell_id'
  belongs_to :centre,         :class_name => 'Centre',        :foreign_key => 'centre_id'

  access_association_by_attribute :centre, :name

  validates_numericality_of :karyotype_low,
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to    => 1,
    :allow_nil                => true

  validates_numericality_of :karyotype_high,
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to    => 1,
    :allow_nil                => true

  SHORT_VALUES = %w( pass fail )
  LONG_VALUES = SHORT_VALUES + ['passb']

  validates_inclusion_of :five_prime_sr_pcr, :in => SHORT_VALUES, :allow_blank => true
  validates_inclusion_of :three_prime_sr_pcr, :in => SHORT_VALUES, :allow_blank => true
  validates_inclusion_of :copy_number, :in => SHORT_VALUES, :allow_blank => true
  validates_inclusion_of :five_prime_lr_pcr, :in => SHORT_VALUES, :allow_blank => true
  validates_inclusion_of :three_prime_lr_pcr, :in => SHORT_VALUES, :allow_blank => true
  validates_inclusion_of :thawing, :in => SHORT_VALUES, :allow_blank => true

  validates_inclusion_of :loa, :in => LONG_VALUES, :allow_blank => true
  validates_inclusion_of :loxp, :in => LONG_VALUES, :allow_blank => true
  validates_inclusion_of :lacz, :in => LONG_VALUES, :allow_blank => true
  validates_inclusion_of :chr1, :in => LONG_VALUES, :allow_blank => true
  validates_inclusion_of :chr8a, :in => LONG_VALUES, :allow_blank => true
  validates_inclusion_of :chr8b, :in => LONG_VALUES, :allow_blank => true
  validates_inclusion_of :chr11a, :in => LONG_VALUES, :allow_blank => true
  validates_inclusion_of :chr11b, :in => LONG_VALUES, :allow_blank => true
  validates_inclusion_of :chry, :in => LONG_VALUES, :allow_blank => true

  def self.get_qc_metrics
    qc_metrics = {
      "copy_number"              => { :name => "Copy Number" },
      "five_prime_lr_pcr"        => { :name => "5' LR-PCR" },
      "three_prime_lr_pcr"       => { :name => "3' LR-PCR" },
      "five_prime_sr_pcr"        => { :name => "5' SR-PCR" },
      "three_prime_sr_pcr"       => { :name => "3' SR-PCR" },
      "thawing"                  => { :name => "Cells Thawed Correctly" },
      "loa"                      => { :name => "LOA"},
      "loxp"                     => { :name => "LOXP"},
      "lacz"                     => { :name => "LACZ"},
      "chr1"                     => { :name => "Chromosome 1"},
      "chr8a"                    => { :name => "Chromosome 8a"},
      "chr8b"                    => { :name => "Chromosome 8b"},
      "chr11a"                   => { :name => "Chromosome 11a"},
      "chr11b"                   => { :name => "Chromosome 11b"},
      "chry"                     => { :name => "Chromosome Y"}
    }

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
      field = attr.to_s.gsub(/\:/, '')
      qc_metrics[field][:values] = []
      SHORT_VALUES.each do |value|
        qc_metrics[field][:values].push value
      end
    end

    long_attributes.each do |attr|
      field = attr.to_s.gsub(/\:/, '')
      qc_metrics[field][:values] = []
      LONG_VALUES.each do |value|
        qc_metrics[field][:values].push value
      end
    end

    qc_metrics.clone
  end

  def is_empty?
    return false if ! self.five_prime_sr_pcr.blank?
    return false if ! self.three_prime_sr_pcr.blank?
    return false if ! self.copy_number.blank?
    return false if ! self.five_prime_lr_pcr.blank?
    return false if ! self.three_prime_lr_pcr.blank?
    return false if ! self.thawing.blank?
    return false if ! self.loa.blank?
    return false if ! self.loxp.blank?
    return false if ! self.lacz.blank?
    return false if ! self.chr1.blank?
    return false if ! self.chr8a.blank?
    return false if ! self.chr8b.blank?
    return false if ! self.chr11a.blank?
    return false if ! self.chry.blank?
    return false if ! self.karyotype_low.blank?
    return false if ! self.karyotype_high.blank?
    return true
  end

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
