class EsCell < ActiveRecord::Base

  # === List of columns ===
  #   id                     : integer 
  #   molecular_structure_id : integer 
  #   targeting_vector_id    : integer 
  #   name                   : string 
  #   created_by             : integer 
  #   updated_by             : integer 
  #   created_at             : datetime 
  #   updated_at             : datetime 
  # =======================

  acts_as_audited
  
  # Associations
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'

  belongs_to :molecular_structure,
    :class_name => 'MolecularStructure',
    :foreign_key => 'molecular_structure_id'

  belongs_to :targeting_vector,
    :class_name => 'TargetingVector',
    :foreign_key => 'targeting_vector_id'

  # Unique constraint
  validates_uniqueness_of :name
  
  # Data validation
  validates_associated  :molecular_structure
  validates_associated  :targeting_vector
  
  validates_presence_of :molecular_structure_id,  :on => :create
  validates_presence_of :targeting_vector_id,     :on => :create
  validates_presence_of :name,                    :on => :create
  
  def targeting_vector_name
    targeting_vector.name if targeting_vector
  end
  
  def targeting_vector_name=(name)
    self.targeting_vector = TargetingVector.find_by_name(name) unless name.blank?
  end
end
