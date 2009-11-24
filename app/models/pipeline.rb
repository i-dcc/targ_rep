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
  
  # Unique constraints
  validates_uniqueness_of :name
  
  # Data validation
  validates_presence_of :name, :on => :create
end
