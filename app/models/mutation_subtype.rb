class MutationSubtype < ActiveRecord::Base
  acts_as_audited
  stampable

  has_many :allele, :class_name => "Allele", :foreign_key => "mutation_sub_type_id"

  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true

end