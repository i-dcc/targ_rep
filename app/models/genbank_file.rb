class GenbankFile < ActiveRecord::Base
  # Associations
  belongs_to :molecular_structure,
    :class_name   => "MolecularStructure",
    :foreign_key  => "molecular_structure_id",
    :validate     => true
  
  # Data validation
  validates_presence_of   :molecular_structure_id, :unless => :nested
  validates_uniqueness_of :molecular_structure_id, :message => "must be unique"
  
  attr_accessor :nested
  
  GenbankFile.include_root_in_json = false
end
