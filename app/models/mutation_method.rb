class MutationMethod < ActiveRecord::Base
  acts_as_audited
  stampable

  has_many :allele, :class_name => "Allele", :foreign_key => "mutation_method_id"

  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true

  def targeted_non_conditional?
    if self.code == 'tnc'
      true
    else
      false
    end
  end

  def knock_out?
    if ['crd', 'tnc'].includes?(self.code)
      true
    else
      false
    end
  end

end