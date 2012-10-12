class MutationType < ActiveRecord::Base
  acts_as_audited
  stampable

  has_many :allele, :class_name => "Allele", :foreign_key => "mutation_type_id"

  validates_presence_of :name
  validates_presence_of :code

  validates_uniqueness_of :name
  validates_uniqueness_of :code

  def targeted_non_conditional?
    if self.code == 'tnc'
      true
    else
      false
    end
  end

  def knock_out?
    if ['crd', 'tnc'].include?(self.code)
      true
    else
      false
    end
  end

end
