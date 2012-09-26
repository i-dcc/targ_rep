class DistributionQc < ActiveRecord::Base
  acts_as_audited

  #stampable

  #attr_accessor :nested

  #attr_accessible :chry

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

  #before_validation do |distribution_qc|
  #
  #  puts "### before_validation '#{@centre_name}'"
  #
  #  if @centre_name && ! self.centre
  #    self.centre = Centre.find_by_name @centre_name
  #    if ! self.centre
  #      errors.add( :centre, "The centre #{@centre_name} is unknown." )
  #    end
  #  end
  #end

  def centre_name
    centre.name
  end

  #def centre_name
  #  if ! @centre_name.blank?
  #    return @centre_name
  #  else
  #    if self.centre
  #      @centre_name = self.centre.try(:name)
  #    end
  #  end
  #end
  #
  #def centre_name=(arg)
  #
  #  puts "### centre_name= #{arg}"
  #
  #  @centre_name = arg
  #end

  #validates_inclusion_of :five_prime_sr_pcr, :in => %w( pass fail )
  #validates_inclusion_of :three_prime_sr_pcr, :in => %w( pass fail )
  #validates_inclusion_of :copy_number, :in => %w( pass fail )
  #validates_inclusion_of :five_prime_lr_pcr, :in => %w( pass fail )
  #validates_inclusion_of :three_prime_lr_pcr, :in => %w( pass fail )
  #validates_inclusion_of :thawing, :in => %w( pass fail )
  #
  #validates_inclusion_of :loa, :in => %w( pass passb fail )
  #validates_inclusion_of :loxp, :in => %w( pass passb fail )
  #validates_inclusion_of :lacz, :in => %w( pass passb fail )
  #validates_inclusion_of :chr1, :in => %w( pass passb fail )
  #validates_inclusion_of :chr8a, :in => %w( pass passb fail )
  #validates_inclusion_of :chr8b, :in => %w( pass fail )
  #validates_inclusion_of :chr11a, :in => %w( pass passb fail )
  #validates_inclusion_of :chr11b, :in => %w( pass passb fail )
  #validates_inclusion_of :chry, :in => %w( pass passb fail )

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
