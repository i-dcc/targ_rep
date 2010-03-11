class MolecularStructure < ActiveRecord::Base

  # === List of columns ===
  #   id                  : integer 
  #   assembly            : string 
  #   chromosome          : string 
  #   strand              : string 
  #   mgi_accession_id    : string 
  #   homology_arm_start  : integer 
  #   homology_arm_end    : integer 
  #   loxp_start          : integer 
  #   loxp_end            : integer 
  #   cassette_start      : integer 
  #   cassette_end        : integer 
  #   cassette            : string 
  #   backbone            : string 
  #   design_type         : string 
  #   design_subtype      : string 
  #   subtype_description : string 
  #   created_by          : integer 
  #   updated_by          : integer 
  #   created_at          : datetime 
  #   updated_at          : datetime 
  #   floxed_start_exon   : string 
  #   floxed_end_exon     : string 
  #   project_design_id   : integer 
  #   mutation_type       : string 
  #   mutation_subtype    : string 
  #   mutation_method     : string 
  #   reporter            : string 
  # =======================

  acts_as_audited
  
  # Associations
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"
  belongs_to :updated_by, :class_name => "User", :foreign_key => "updated_by"
  
  has_one :genbank_file, :class_name => "GenbankFile", :foreign_key => "molecular_structure_id"
  accepts_nested_attributes_for :genbank_file, :allow_destroy  => true
  
  has_many :targeting_vectors, :class_name => "TargetingVector", :foreign_key => "molecular_structure_id"
  accepts_nested_attributes_for :targeting_vectors, :allow_destroy  => true
  
  has_many :es_cells, :class_name => "EsCell", :foreign_key => "molecular_structure_id"
  accepts_nested_attributes_for :es_cells, :allow_destroy  => true
  
  # Unique constraint
  validates_uniqueness_of :project_design_id,
    :scope => [
      :mgi_accession_id, :assembly, :chromosome, :strand,
      :cassette, :backbone,
      :homology_arm_start, :homology_arm_end,
      :cassette_start, :cassette_end,
      :loxp_start, :loxp_end
    ],
    :message => "must have unique design features"
  
  # Data validation
  validates_presence_of [
    :mgi_accession_id,
    :assembly,
    :chromosome,
    :strand,
    :design_type,
    :homology_arm_start,
    :homology_arm_end,
    :cassette_start,
    :cassette_end
  ]
  
  validates_inclusion_of :strand,
    :in => ["+", "-"],
    :message => "should be '+' or '-'.",
    :allow_nil => true
  
  validates_inclusion_of :chromosome,
    :in => ('1'..'19').to_a + ['X', 'Y', 'MT'],
    :message => "is not a valid mouse chromosome",
    :allow_nil => true
  
  validates_inclusion_of :design_type,
    :in => ['Knock Out', 'Deletion', 'Insertion'],
    :message => "should be 'Knockout', 'Deletion' or 'Insertion'.",
    :allow_nil => true
  
  validates_format_of :mgi_accession_id,
    :with => /^MGI\:\d+$/,
    :message => "is not a valid MGI accession ID",
    :allow_nil => true
  
  validates_numericality_of :homology_arm_start,  :only_integer => true, :greater_than => 0, :allow_nil => true
  validates_numericality_of :homology_arm_end,    :only_integer => true, :greater_than => 0, :allow_nil => true
  validates_numericality_of :cassette_start,      :only_integer => true, :greater_than => 0, :allow_nil => true
  validates_numericality_of :cassette_end,        :only_integer => true, :greater_than => 0, :allow_nil => true
  validates_numericality_of :loxp_start,          :only_integer => true, :greater_than => 0, :allow_nil => true
  validates_numericality_of :loxp_end,            :only_integer => true, :greater_than => 0, :allow_nil => true
  
  validate :has_right_features, 
    :unless => "[mgi_accession_id, assembly, chromosome, strand, design_type,
    homology_arm_start, homology_arm_end, cassette_start, cassette_end].any?(&:nil?)"
  
  before_validation :set_mutation_details
  
  public
    def to_json( options = {} )
      MolecularStructure.include_root_in_json = false
      options.update(
        :include => {
          :es_cells => { :except => [
              :molecular_structure_id,
              :created_at, :updated_at,
              :created_by, :updated_by
          ]},
          :targeting_vectors => { :except => [
              :molecular_structure_id,
              :created_at, :updated_at,
              :created_by, :updated_by
          ]},
          :genbank_file => { :except => [
              :molecular_structure_id,
              :created_at, :updated_at,
              :created_by, :updated_by
          ]},
        }
      )
      
      super( options )
    end

    def to_xml( options = {} )
      options.update(
        :skip_types => true,
        :include => {
          :es_cells => { :except => [
              :molecular_structure_id,
              :created_at, :updated_at,
              :created_by, :updated_by
          ]},
          :targeting_vectors => { :except => [
              :molecular_structure_id,
              :created_at, :updated_at,
              :created_by, :updated_by
          ]}
        }
      )
      super( options )
    end
    
    def targeted_trap?
      (self.design_type == 'Knock Out' and self.loxp_start.nil?) ? 'Yes' : 'No'
    end

  protected
    def has_right_features
      error_msg = "cannot be greater than %s position on this strand (#{strand})"
      
      case strand
      when '+'
        if homology_arm_start > cassette_start
          errors.add( :homology_arm_start, error_msg % "cassette start" )
        end
        if cassette_start > cassette_end
          errors.add( :cassette_start, error_msg % "cassette end" )
        end
        # With LoxP site
        if loxp_start and loxp_end
          if cassette_end > loxp_start
            errors.add( :cassette_end, error_msg % "loxp start" )
          end
          if loxp_start > loxp_end
            errors.add( :loxp_start, error_msg % "loxp end" )
          end
          if loxp_end > homology_arm_end
            errors.add( :loxp_end, error_msg % "homology arm end" )
          end
        # Without LoxP site
        else
          if cassette_end > homology_arm_end
            errors.add( :cassette_end, error_msg % "homology arm end" )
          end
        end
      when '-'
        if homology_arm_start < cassette_start
          errors.add( :cassette_start, error_msg % "homology arm start" )
        end
        if cassette_start < cassette_end
          errors.add( :cassette_end, error_msg % "cassette start" )
        end
        # With LoxP site
        if loxp_start and loxp_end
          if cassette_end < loxp_start
            errors.add( :loxp_start, error_msg % "cassette end" )
          end
          if loxp_start < loxp_end
            errors.add( :loxp_end, error_msg % "loxp start" )
          end
          if loxp_end < homology_arm_end
            errors.add( :homology_arm_end, error_msg % "loxp end" )
          end
        # Without LoxP site
        else
          if cassette_end < homology_arm_end
            errors.add( :homology_arm_end, error_msg % "cassette end" )
          end
        end
      end
      
      if design_type != "Knock Out"
        unless loxp_start.nil? and loxp_end.nil?
          errors.add(:loxp_start, "has to be blank for this design type")
          errors.add(:loxp_end,   "has to be blank for this design type")
        end
      end
    end
    
    def set_mutation_details
      self.mutation_type = 'targeted_mutation'
      
      self.mutation_subtype = case self.design_type
        when 'Deletion'   then 'deletion'
        when 'Insertion'  then 'insertion'
        when 'Knock Out'  then self.loxp_start.nil? ? 'targeted_non_conditional' : 'conditional_ready'
      end
      
      if ['conditional_ready', 'insertion', 'deletion'].include? self.mutation_subtype
        if self.design_subtype and self.design_subtype === 'domain'
          self.mutation_method = 'domain_disruption'
        else
          self.mutation_method = 'frameshift'
        end
      end
      
      self.reporter = nil
    end
end
