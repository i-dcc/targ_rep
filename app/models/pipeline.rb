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
    
  has_many :molecular_structures, :through => :targeting_vectors
  has_many :es_cells,             :through => :targeting_vectors
  
  # Unique constraints
  validates_uniqueness_of :name
  
  # Data validation
  validates_presence_of :name, :on => :create
  
  Pipeline.include_root_in_json = false
end
