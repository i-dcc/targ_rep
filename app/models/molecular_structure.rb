class MolecularStructure < ActiveRecord::Base

  # === List of columns ===
  #   id                        : integer 
  #   genbank_file_id           : integer 
  #   assembly                  : string 
  #   chromosome                : string 
  #   strand                    : string 
  #   mgi_accession_id          : string 
  #   allele_symbol_superscript : string 
  #   homology_arm_start        : integer 
  #   homology_arm_end          : integer 
  #   loxp_start                : integer 
  #   loxp_end                  : integer 
  #   cassette_start            : integer 
  #   cassette_end              : integer 
  #   cassette                  : string 
  #   backbone                  : string 
  #   design_type               : string 
  #   design_subtype            : string 
  #   subtype_description       : string 
  #   created_by                : integer 
  #   updated_by                : integer 
  #   created_at                : datetime 
  #   updated_at                : datetime 
  # =======================

  acts_as_audited
  
  # Associations
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"
  belongs_to :updated_by, :class_name => "User", :foreign_key => "updated_by"
  
  has_many :targeting_vectors,
    :class_name => "TargetingVector",
    :foreign_key => "molecular_structure_id"
  
  has_many :es_cells,
    :class_name => "EsCell",
    :foreign_key => "molecular_structure_id"
  
  # Unique constraint
  validates_uniqueness_of :mgi_accession_id,
    :scope => [
      :assembly, :chromosome, :strand,
      :homology_arm_start, :homology_arm_end,
      :cassette_start, :cassette_end,
      :loxp_start, :loxp_end,
      :cassette, :backbone,
      :allele_symbol_superscript
    ],
    :message => "must have unique design features"
  
  # Data validation
  validates_presence_of :mgi_accession_id,          :on => :create
  validates_presence_of :assembly,                  :on => :create
  validates_presence_of :chromosome,                :on => :create
  validates_presence_of :strand,                    :on => :create
  validates_presence_of :design_type,               :on => :create
  validates_presence_of :homology_arm_start,        :on => :create
  validates_presence_of :homology_arm_end,          :on => :create
  validates_presence_of :cassette_start,            :on => :create
  validates_presence_of :cassette_end,              :on => :create
  validates_presence_of :allele_symbol_superscript, :on => :create
  
  validates_inclusion_of :strand,
    :in => ["+", "-"],
    :message => "should be '+' or '-'.",
    :allow_nil => true
  
  validates_inclusion_of :chromosome,
    :in => ('1'..'19').to_a + ['X', 'Y', 'MT'],
    :message => "is not a valid mouse chromosome",
    :allow_nil => true
  
  validates_inclusion_of :design_type,
    :in => ['Knock Out', 'Deletion'],
    :message => "should be 'Knockout' or 'Deletion'",
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
  
  validate :has_right_features
  
  protected
    def has_right_features
      case strand
      when '+'
        error_msg = "cannot be greater than %s position on this strand (+)"
        if cassette_start > cassette_end
          errors.add( :cassette_start, error_msg % "cassette end" )
        end
        if homology_arm_start > homology_arm_end
          errors.add( :homology_arm_start, error_msg % "homology arm end" )
        end
        if loxp_start and loxp_end and loxp_start > loxp_end
          errors.add( :loxp_start, error_msg % "loxp end" )
        end
        if homology_arm_start > cassette_start
          errors.add( :homology_arm_start, error_msg % "cassette start")
        end
        if loxp_start and cassette_end > loxp_start
          errors.add( :cassette_end, error_msg % "LoxP start")
        end
        if loxp_end and loxp_end > homology_arm_end
          errors.add( :loxp_end, error_msg % "homology arm start")
        end
      
      when '-'
        error_msg = "cannot be greater than %s position on this strand (-)"
        if cassette_start and cassette_end and cassette_start < cassette_end
          errors.add( :cassette_start, error_msg % "cassette end" )
        end
        if homology_arm_start and homology_arm_end and homology_arm_start < homology_arm_end
          errors.add( :homology_arm_start, error_msg % "homology arm end" )
        end
        if loxp_start and loxp_end and loxp_start < loxp_end
          errors.add( :loxp_start, error_msg % "loxp end" )
        end
        if homology_arm_start < cassette_start
          errors.add( :homology_arm_start, error_msg % "cassette start")
        end
        if loxp_start and cassette_end < loxp_start
          errors.add( :cassette_end, error_msg % "LoxP start")
        end
        if loxp_end and loxp_end < homology_arm_end
          errors.add( :loxp_end, error_msg % "homology arm start")
        end
      end
      
      if design_type != "Knock Out"
        unless loxp_start.nil? and loxp_end.nil?
          errors.add(:loxp_start, "has to be blank for this design type")
          errors.add(:loxp_end,   "has to be blank for this design type")
        end
      end
    end
end
