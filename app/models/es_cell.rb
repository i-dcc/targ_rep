class EsCell < ActiveRecord::Base

  # === List of columns ===
  #   id                        : integer 
  #   molecular_structure_id    : integer 
  #   targeting_vector_id       : integer 
  #   parental_cell_line        : string 
  #   allele_symbol_superscript : string 
  #   name                      : string 
  #   created_by                : integer 
  #   updated_by                : integer 
  #   created_at                : datetime 
  #   updated_at                : datetime 
  #   comment                   : string 
  #   contact                   : string 
  #   upper_LR_check            : string 
  #   upper_SR_check            : string 
  #   lower_LR_check            : string 
  #   lower_SR_check            : string 
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
  
  validates_presence_of :molecular_structure_id,  :on => :save, :unless => :nested
  validates_presence_of :targeting_vector_id,     :on => :save, :unless => :nested
  validates_presence_of :name,                    :on => :create
  
  attr_accessor :nested
  
  def targeting_vector_name
    targeting_vector.name if targeting_vector
  end
  
  def targeting_vector_name=(name)
    self.targeting_vector = TargetingVector.find_by_name(name) unless name.blank?
  end
  
  public
    def to_json( options = {} )
      EsCell.include_root_in_json = false
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
