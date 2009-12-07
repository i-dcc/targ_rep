class TargetingVector < ActiveRecord::Base

  # === List of columns ===
  #   id                     : integer 
  #   pipeline_id            : integer 
  #   molecular_structure_id : integer 
  #   ikmc_project_id        : string 
  #   name                   : string 
  #   intermediate_vector    : string 
  #   parental_cell_line     : string 
  #   created_by             : integer 
  #   updated_by             : integer 
  #   created_at             : datetime 
  #   updated_at             : datetime 
  # =======================

  acts_as_audited

  # Associations
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'

  belongs_to :pipeline,
    :class_name => "Pipeline",
    :foreign_key => "pipeline_id"

  belongs_to :molecular_structure,
    :class_name => 'MolecularStructure',
    :foreign_key => 'molecular_structure_id'
    
  has_many :es_cells,
    :class_name => "EsCell",
    :foreign_key => "targeting_vector_id"
  
  # Helper for handling creation/update of associated es_cell in the
  # targeting_vector's form
  accepts_nested_attributes_for :es_cells, :allow_destroy => true

  has_one :genbank_file,
    :class_name => "GenbankFile",
    :foreign_key => "genbank_file_id"

  # Unique constraint
  validates_uniqueness_of :name, :scope => :pipeline_id

  # Data validation
  validates_associated  :pipeline
  validates_associated  :molecular_structure

  validates_presence_of :pipeline_id,             :on => :create
  validates_presence_of :molecular_structure_id,  :on => :create
  validates_presence_of :ikmc_project_id,         :on => :create
  validates_presence_of :name,                    :on => :create

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

    def xml( options = {} )
      options.update(
        :skip_types => true,
        :include => {
          :created_by => { :only => [:id, :username] },
          :updated_by => { :only => [:id, :username] }
        }
      )
    end
end
