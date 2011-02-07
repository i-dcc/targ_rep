class EsCell < ActiveRecord::Base  
  acts_as_audited
  stampable
  
  attr_accessor :nested
  
  ##
  ## Associations
  ##
  
  belongs_to :allele,           :class_name => 'Allele',          :foreign_key => 'allele_id',           :validate => true
  belongs_to :targeting_vector, :class_name => 'TargetingVector', :foreign_key => 'targeting_vector_id', :validate => true
  
  has_many :es_cell_qc_conflicts, :class_name => 'EsCellQcConflict', :foreign_key => "es_cell_id", :dependent => :destroy
  
  accepts_nested_attributes_for :es_cell_qc_conflicts, :allow_destroy => true
  
  ##
  ## Data validation
  ##
  
  validates_uniqueness_of :name, :message => 'This ES Cell name has already been taken'
  
  validates_presence_of :allele_id, :on => :save, :unless => :nested
  validates_presence_of :name,      :on => :create
  
  validate :allele_consistency,          :unless => "[allele,targeting_vector].any?(&:nil?)"
  validate :ikmc_project_id_consistency, :if     => :test_ikmc_project_id_consistency?
    
  # Validate QC fields - the ESCELL_QC_OPTIONS constant comes from the 
  # es_cell_qc_options.rb initializer.
  ESCELL_QC_OPTIONS.each_key do |qc_field|
    validates_inclusion_of qc_field,
      :in        => ESCELL_QC_OPTIONS[qc_field.to_s][:values],
      :message   => "This QC metric can only be set as: #{ESCELL_QC_OPTIONS[qc_field.to_s][:values].join(', ')}",
      :allow_nil => true
  end
  
  validates_numericality_of :distribution_qc_karyotype_low,
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to    => 1,
    :allow_nil                => true
    
  validates_numericality_of :distribution_qc_karyotype_high,
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to    => 1,
    :allow_nil                => true
  
  validates_format_of :mgi_allele_id,
    :with      => /^MGI\:\d+$/,
    :message   => "is not a valid MGI Allele ID",
    :allow_nil => true
  
  ##
  ## Filters
  ##
  
  before_save :set_mirko_ikmc_project_id
  before_validation :convert_blanks_to_nil
  before_validation :stamp_tv_project_id_on_cell,       :if     => Proc.new { |a| a.ikmc_project_id.nil? }
  before_validation :convert_ikmc_project_id_to_string, :unless => Proc.new { |a| a.ikmc_project_id.is_a?(String) }

  ##
  ## Methods
  ##
  
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
          :creator => { :only => [:id, :username] },
          :updater => { :only => [:id, :username] }
        }
      )
      super( options )
    end
    
    def to_xml( options = {} )
      options.update(
        :skip_types => true,
        :include => {
          :creator => { :only => [:id, :username] },
          :updater => { :only => [:id, :username] }
        }
      )
    end
  
  protected
    # Convert any blank attribute strings to nil...
    def convert_blanks_to_nil
      self.attributes.each do |name,value|
        self.send("#{name}=".to_sym, nil) if value.is_a?(String) and value.empty?
      end
    end
    
    # Helper function to solve the IKMC Project ID consistency validation 
    # errors when people are passing integers in as the id...
    def convert_ikmc_project_id_to_string
      self.ikmc_project_id = ikmc_project_id.to_s
    end
    
    # Helper function to stamp the IKMC Project ID from 
    # the parent targeting vector on this cell if it's not 
    # been specifically entered
    def stamp_tv_project_id_on_cell
      if ikmc_project_id.nil? and targeting_vector
        self.ikmc_project_id = targeting_vector.ikmc_project_id
      end
    end
    
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

    # Set mirKO ikmc_project_ids to "mirKO#{self.allele_id}"
    def set_mirko_ikmc_project_id
      if self.ikmc_project_id.nil? and self.allele.pipeline_id == 5
        self.ikmc_project_id = "mirKO#{ self.allele_id }"
      end
    end
end
