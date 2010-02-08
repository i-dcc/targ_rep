class Pipeline < ActiveRecord::Base

  # === List of columns ===
  #   id         : integer 
  #   name       : string 
  #   created_at : datetime 
  #   updated_at : datetime 
  # =======================

  # Associations
  has_many :targeting_vectors, 
    :class_name => "TargetingVector",
    :foreign_key => "pipeline_id"
  
  has_many :es_cells, :through => :targeting_vectors, :uniq => true
  
  # Unique constraints
  validates_uniqueness_of :name
  
  # Data validation
  validates_presence_of :name
  
  Pipeline.include_root_in_json = false
  
  def molecular_structures
    tv_mol_structs = targeting_vectors.collect(&:molecular_structure_id).uniq
    ec_mol_structs = es_cells.collect(&:molecular_structure_id).uniq
    (tv_mol_structs + ec_mol_structs).uniq
    MolecularStructure.find( (tv_mol_structs + ec_mol_structs).uniq )
  end
end
