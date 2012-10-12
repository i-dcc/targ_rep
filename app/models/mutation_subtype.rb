class MutationSubtype < ActiveRecord::Base
  acts_as_audited
  stampable

  has_many :allele, :class_name => "Allele", :foreign_key => "mutation_subtype_id"

  validates_presence_of :name
  validates_presence_of :code

  validates_uniqueness_of :name
  validates_uniqueness_of :code

end
