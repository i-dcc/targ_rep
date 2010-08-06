class EsCell < ActiveRecord::Base  
  acts_as_audited
  attr_accessor :nested
  
  # Associations
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'
  
  belongs_to :allele,
    :class_name   => 'Allele',
    :foreign_key  => 'allele_id',
    :validate     => true
  
  belongs_to :targeting_vector,
    :class_name   => 'TargetingVector',
    :foreign_key  => 'targeting_vector_id',
    :validate     => true
  
  # Unique constraint
  validates_uniqueness_of :name, :message => 'This ES Cell name has already been taken'
  
  # Data validation
  validates_presence_of :allele_id, :on => :save, :unless => :nested
  validates_presence_of :name,      :on => :create
  
  validate :allele_consistency,
    :unless => "[allele,targeting_vector].any?(&:nil?)"
  
  validate :ikmc_project_id_consistency, :if => :test_ikmc_project_id_consistency?
    
  # Validate QC fields - the ESCELL_QC_OPTIONS constant comes from the 
  # es_cell_qc_options.rb initializer.
  ESCELL_QC_OPTIONS.each_key do |qc_field|
    validates_inclusion_of qc_field,
      :in        => ESCELL_QC_OPTIONS[qc_field],
      :unless    => Proc.new { |a| [nil,''].include?(a.attributes[qc_field.to_s]) },
      :message   => "This QC metric can only be set as: #{ESCELL_QC_OPTIONS[qc_field].join(', ')}"
  end
  
  validates_numericality_of :distribution_qc_karyotype_low,
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to => 1,
    :unless    => Proc.new { |a| [nil,''].include?(a.distribution_qc_karyotype_low) }
    
  validates_numericality_of :distribution_qc_karyotype_high,
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to => 1,
    :unless    => Proc.new { |a| [nil,''].include?(a.distribution_qc_karyotype_high) }
  
  def before_validation
    if ikmc_project_id.nil? and targeting_vector
      self.ikmc_project_id = targeting_vector.ikmc_project_id
    end
  end
  
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
    def allele_consistency
      my_mol_struct = self.allele
      targ_vec_mol_struct = self.targeting_vector.allele
      
      unless \
           targ_vec_mol_struct.id == my_mol_struct.id \
        or ( \
              my_mol_struct.mgi_accession_id  == targ_vec_mol_struct.mgi_accession_id   \
          and my_mol_struct.project_design_id == targ_vec_mol_struct.project_design_id  \
          and my_mol_struct.design_type       == targ_vec_mol_struct.design_type        \
          and my_mol_struct.cassette          == targ_vec_mol_struct.cassette           \
          and my_mol_struct.backbone          == targ_vec_mol_struct.backbone           \
        )
        errors.add( :targeting_vector_id, "targeting vector's molecular structure differs from ES cell's molecular structure" )
      end
    end
    
    def test_ikmc_project_id_consistency?
      test = false
      
      if ikmc_project_id != nil and ikmc_project_id != ""
        if self.targeting_vector and ( self.targeting_vector.ikmc_project_id != nil and self.targeting_vector.ikmc_project_id != "" )
          test = true
        end
      end
      
      return test
    end
    
    def ikmc_project_id_consistency
      if ikmc_project_id != self.targeting_vector.ikmc_project_id
        errors.add( :ikmc_project_id, "targeting vector's IKMC Project ID is different.")
      end
    end
end
