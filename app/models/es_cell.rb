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
    :class_name   => 'MolecularStructure',
    :foreign_key  => 'molecular_structure_id',
    :validate     => true
  
  belongs_to :targeting_vector,
    :class_name   => 'TargetingVector',
    :foreign_key  => 'targeting_vector_id',
    :validate     => true
  
  # Unique constraint
  validates_uniqueness_of :name, :message => 'This ES Cell name has already been taken'
  
  # Data validation
  validates_presence_of :molecular_structure_id,  :on => :save, :unless => :nested
  validates_presence_of :name,                    :on => :create
  
  validate :molecular_structure_consistency,
      :unless => "[molecular_structure,targeting_vector].any?(&:nil?)"
  
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
  
  protected
    # Compares targeting vector's molecular structure to
    # ES cell's molecular structure
    def molecular_structure_consistency
      my_mol_struct = self.molecular_structure
      targ_vec_mol_struct = self.targeting_vector.molecular_structure
      
      unless targ_vec_mol_struct.id == my_mol_struct.id \
      or (my_mol_struct.mgi_accession_id  == targ_vec_mol_struct.mgi_accession_id   \
      and my_mol_struct.project_design_id == targ_vec_mol_struct.project_design_id  \
      and my_mol_struct.design_type       == targ_vec_mol_struct.design_type        \
      and my_mol_struct.cassette          == targ_vec_mol_struct.cassette           \
      and my_mol_struct.backbone          == targ_vec_mol_struct.backbone)
        errors.add( :targeting_vector_id, "targeting vector's molecular structure differs from ES cell's molecular structure" )
      end
    end
end
