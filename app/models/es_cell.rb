class EsCell < ActiveRecord::Base  
  acts_as_audited
  attr_accessor :nested
  
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
  
  validate :ikmc_project_id_consistency, :on => :save,
    :unless => "[ikmc_project_id,targeting_vector].any?(&:nil?)"
  
  # Validate QC fields
  pass_fail_only_qc_fields = [
    :qc_five_prime_lr_pcr,
    :qc_three_prime_lr_pcr,
    :qc_map_test,
    :qc_tv_backbone_assay,
    :qc_loxp_confirmation,
    :qc_loss_of_wt_allele,
    :qc_neo_count_qpcr,
    :qc_lacz_sr_pcr,
    :qc_mutant_specific_sr_pcr,
    :qc_five_prime_cassette_integrity,
    :qc_neo_sr_pcr
  ]
  
  pass_fail_only_qc_fields.each do |qc_field|
    validates_inclusion_of qc_field,
      :in        => %w( pass fail ),
      :allow_nil => true,
      :on        => :create,
      :message   => "This QC metric can only be set as 'pass' or 'fail'"
  end
  
  validates_inclusion_of :qc_karyotype,
    :in        => %w( pass fail limit ),
    :allow_nil => true,
    :on        => :create,
    :message   => "This QC metric can only be set as 'pass', 'fail' or 'limit'"
  
  validates_inclusion_of :qc_southern_blot,
    :in        => ["pass","fail 5' end","fail 3' end","fail both ends","double integration"],
    :allow_nil => true,
    :on        => :create,
    :message   => "This QC metric can only be set as \"pass\", \"fail 5' end\", \"fail 3' end\", \"fail both ends\" or \"double integration\""
  
  
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
    
    def ikmc_project_id_consistency
      if ikmc_project_id != self.targeting_vector.ikmc_project_id
        errors.add( :ikmc_project_id, "targeting vector's IKMC Project ID is different.")
      end
    end
end
