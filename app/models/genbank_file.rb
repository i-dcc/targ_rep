class GenbankFile < ActiveRecord::Base
  # Associations
  belongs_to :allele,
    :class_name   => "Allele",
    :foreign_key  => "allele_id",
    :validate     => true
  
  # Data validation
  validates_presence_of   :allele_id, :unless => :nested
  validates_uniqueness_of :allele_id, :message => "must be unique"
  
  attr_accessor :nested
  
  GenbankFile.include_root_in_json = false
end
