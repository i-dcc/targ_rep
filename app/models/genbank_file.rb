class GenbankFile < ActiveRecord::Base

  # === List of columns ===
  #   id                     : integer 
  #   molecular_structure_id : integer 
  #   escell_clone           : text 
  #   targeting_vector       : text 
  #   created_at             : datetime 
  #   updated_at             : datetime 
  # =======================
  
  # Associations
  belongs_to :molecular_structure,
    :class_name => "MolecularStructure",
    :foreign_key => "molecular_structure_id"
  
  # Data validation
  validates_associated  :molecular_structure
end
