class TargetingVector < ActiveRecord::Base

  # === List of columns ===
  #   id                     : integer 
  #   molecular_structure_id : integer 
  #   ikmc_project_id        : string 
  #   name                   : string 
  #   intermediate_vector    : string 
  #   created_by             : integer 
  #   updated_by             : integer 
  #   created_at             : datetime 
  #   updated_at             : datetime 
  #   display                : boolean 
  # =======================

  acts_as_audited

  # Associations
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'

  belongs_to :molecular_structure,
    :class_name   => 'MolecularStructure',
    :foreign_key  => 'molecular_structure_id',
    :validate     => true
    
  has_many :es_cells,
    :class_name   => "EsCell",
    :foreign_key  => "targeting_vector_id"
  accepts_nested_attributes_for :es_cells, :allow_destroy => true

  # Unique constraint
  validates_uniqueness_of :name, :message => 'This Targeting Vector name has already been taken'

  # Data validation
  validates_presence_of :molecular_structure_id,  :on => :save, :unless => :nested
  validates_presence_of :name,                    :on => :create

  attr_accessor :nested
  
  public
    def to_json( options = {} )
      TargetingVector.include_root_in_json = false
      options.update(
        :include => {
          :created_by => { :only => [:id, :username] },
          :updated_by => { :only => [:id, :username] }
        }
      )
      super( options )
    end

    def to_xml( options = {} )
      options.update(
        :skip_types => true,
        :include => {
          :created_by => { :only => [:id, :username] },
          :updated_by => { :only => [:id, :username] }
        }
      )
    end
end
