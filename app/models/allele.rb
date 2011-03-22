class Allele < ActiveRecord::Base
  acts_as_audited
  stampable
  
  ##
  ## Associations
  ##
  
  belongs_to :pipeline,          :class_name => "Pipeline",        :foreign_key => "pipeline_id", :validate => true
  has_one    :genbank_file,      :class_name => "GenbankFile",     :foreign_key => "allele_id",   :dependent => :destroy
  has_many   :targeting_vectors, :class_name => "TargetingVector", :foreign_key => "allele_id",   :dependent => :destroy
  has_many   :es_cells,          :class_name => "EsCell",          :foreign_key => "allele_id",   :dependent => :destroy
  
  accepts_nested_attributes_for :genbank_file,      :allow_destroy  => true
  accepts_nested_attributes_for :targeting_vectors, :allow_destroy  => true
  accepts_nested_attributes_for :es_cells,          :allow_destroy  => true
  
  ##
  ## Validations
  ##
  
  validates_uniqueness_of :project_design_id,
    :scope => [
      :mgi_accession_id, :assembly, :chromosome, :strand,
      :cassette, :backbone,
      :homology_arm_start, :homology_arm_end,
      :cassette_start, :cassette_end,
      :loxp_start, :loxp_end
    ],
    :message => "must have unique design features"
  
  validates_presence_of [
    :mgi_accession_id,
    :assembly,
    :chromosome,
    :strand,
    :design_type,
    :homology_arm_start,
    :homology_arm_end,
    :cassette_start,
    :cassette_end,
    :pipeline_id,
    :cassette,
    :cassette_type
  ]
  
  validates_inclusion_of :cassette_type, 
    :in => ['Promotorless','Promotor Driven'], 
    :message => "Cassette Type can only be 'Promotorless' or 'Promotor Driven'"
  
  validates_inclusion_of :strand,
    :in         => ["+", "-"],
    :message    => "should be '+' or '-'."
  
  validates_inclusion_of :chromosome,
    :in         => ('1'..'19').to_a + ['X', 'Y', 'MT'],
    :message    => "is not a valid mouse chromosome"
  
  validates_inclusion_of :design_type,
    :in         => ['Knock Out', 'Deletion', 'Insertion'],
    :message    => "should be 'Knockout', 'Deletion' or 'Insertion'."
  
  validates_format_of :mgi_accession_id,
    :with       => /^MGI\:\d+$/,
    :message    => "is not a valid MGI Accession ID"
  
  validates_format_of :floxed_start_exon,
    :with       => /^ENSMUSE\d+$/,
    :message    => "is not a valid Ensembl Exon ID",
    :allow_nil  => true
  
  validates_format_of :floxed_end_exon,
    :with       => /^ENSMUSE\d+$/,
    :message    => "is not a valid Ensembl Exon ID",
    :allow_nil  => true
  
  validates_numericality_of :homology_arm_start, :only_integer => true, :greater_than => 0
  validates_numericality_of :homology_arm_end,   :only_integer => true, :greater_than => 0
  validates_numericality_of :cassette_start,     :only_integer => true, :greater_than => 0
  validates_numericality_of :cassette_end,       :only_integer => true, :greater_than => 0
  validates_numericality_of :loxp_start,         :only_integer => true, :greater_than => 0, :allow_nil => true
  validates_numericality_of :loxp_end,           :only_integer => true, :greater_than => 0, :allow_nil => true
  
  validate :has_right_features, 
    :unless => "[mgi_accession_id, assembly, chromosome, strand, design_type,
    homology_arm_start, homology_arm_end, cassette_start, cassette_end].any?(&:nil?)"
  
  validate :has_correct_cassette_type
  
  ##
  ## Filters
  ##
  
  before_validation :set_mutation_details_and_clean_blanks
  
  ##
  ## Methods
  ##
  
  public
    def to_json( options = {} )
      Allele.include_root_in_json = false
      options.update(
        :include => {
          :es_cells => { :except => [
              :allele_id,
              :created_at, :updated_at,
              :creator, :updater
          ]},
          :targeting_vectors => { :except => [
              :allele_id,
              :created_at, :updated_at,
              :creator, :updater
          ]},
          :genbank_file => { :except => [
              :allele_id,
              :created_at, :updated_at,
              :creator, :updater
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
              :allele_id,
              :created_at, :updated_at,
              :creator, :updater
          ]},
          :targeting_vectors => { :except => [
              :allele_id,
              :created_at, :updated_at,
              :creator, :updater
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
    
    def set_mutation_details_and_clean_blanks
      # Set the mutation details
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
      
      # Convert any blank strings to nil...
      self.attributes.each do |name,value|
        self.send("#{name}=".to_sym, nil) if value.is_a?(String) and value.empty?
      end
    end
    
    def has_correct_cassette_type
      known_cassettes = {
        'L1L2_6XOspnEnh_Bact_P'   => 'Promotor Driven',
        'L1L2_Bact_P'             => 'Promotor Driven',
        'L1L2_Del_BactPneo_FFL'   => 'Promotor Driven',
        'L1L2_GOHANU'             => 'Promotor Driven',
        'L1L2_hubi_P'             => 'Promotor Driven',
        'L1L2_Pgk_P'              => 'Promotor Driven',
        'L1L2_Pgk_PM'             => 'Promotor Driven',
        'PGK_EM7_PuDtk_bGHpA'     => 'Promotor Driven',
        'pL1L2_PAT_B0'            => 'Promotor Driven',
        'TM-ZEN-UB1'              => 'Promotor Driven',
        'ZEN-Ub1'                 => 'Promotor Driven',
        'ZEN-UB1.GB'              => 'Promotor Driven',
        'L1L2_gt0'                => 'Promotorless',
        'L1L2_gt1'                => 'Promotorless',
        'L1L2_gt2'                => 'Promotorless',
        'L1L2_gtk'                => 'Promotorless',
        'L1L2_NTARU-0'            => 'Promotorless',
        'L1L2_NTARU-1'            => 'Promotorless',
        'L1L2_NTARU-2'            => 'Promotorless',
        'L1L2_NTARU-K'            => 'Promotorless',
        'L1L2_st0'                => 'Promotorless',
        'L1L2_st1'                => 'Promotorless',
        'L1L2_st2'                => 'Promotorless'
      }
      
      unless known_cassettes[cassette].nil?
        if known_cassettes[cassette] != cassette_type
          errors.add( :cassette_type, "The cassette #{cassette} is a known #{known_cassettes[cassette]} cassette - please correct this field." )
        end
      end
    end
    
end
