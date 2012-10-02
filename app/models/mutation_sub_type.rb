class MutationSubType < ActiveRecord::Base
  acts_as_audited
  stampable

  has_many :allele, :class_name => "Allele", :foreign_key => "mutation_subtype",   :dependent => :destroy
end