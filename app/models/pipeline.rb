class Pipeline < ActiveRecord::Base

  # === List of columns ===
  #   id         : integer 
  #   name       : string 
  #   created_at : datetime 
  #   updated_at : datetime 
  # =======================

  # Associations
  has_many :molecular_structures,
    :class_name => "MolecularStructure",
    :foreign_key => "pipeline_id"
  
  has_many :es_cells, :through => :molecular_structures, :uniq => true
  
  # Unique constraints
  validates_uniqueness_of :name, :message => 'This pipeline name has already been taken'
  
  # Data validation
  validates_presence_of :name
  
  Pipeline.include_root_in_json = false
end
