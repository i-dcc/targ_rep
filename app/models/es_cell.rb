class EsCell < ActiveRecord::Base  
  acts_as_audited
  stampable

  attr_accessor :nested

  ##
  ## Associations
  ##

  belongs_to :pipeline,         :class_name => 'Pipeline',        :foreign_key => 'pipeline_id',         :validate => true
  belongs_to :allele,           :class_name => 'Allele',          :foreign_key => 'allele_id',           :validate => true
  belongs_to :targeting_vector, :class_name => 'TargetingVector', :foreign_key => 'targeting_vector_id', :validate => true

  has_many :es_cell_qc_conflicts, :class_name => 'EsCellQcConflict', :foreign_key => 'es_cell_id', :dependent => :destroy

  accepts_nested_attributes_for :es_cell_qc_conflicts, :allow_destroy => true

  ##
  ## Data validation
  ##

  validates_uniqueness_of :name, :message => 'This ES Cell name has already been taken'

  validates_presence_of :pipeline_id
  validates_presence_of :allele_id, :on => :save, :unless => :nested
  validates_presence_of :name
  validates_presence_of :parental_cell_line

  validate :allele_consistency, :unless => "[allele,targeting_vector].any?(&:nil?)"
  validate :set_and_check_strain

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

    def report_to_public?
      self.report_to_public
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
      my_allele       = self.allele
      targ_vec_allele = self.targeting_vector.allele

      unless \
           targ_vec_allele.id == my_allele.id \
        or ( \
              my_allele.mgi_accession_id    == targ_vec_allele.mgi_accession_id   \
          and my_allele.project_design_id   == targ_vec_allele.project_design_id  \
          and my_allele.design_type         == targ_vec_allele.design_type        \
          and my_allele.cassette            == targ_vec_allele.cassette           \
          and my_allele.backbone            == targ_vec_allele.backbone           \
          and my_allele.homology_arm_start  == targ_vec_allele.homology_arm_start \
          and my_allele.homology_arm_end    == targ_vec_allele.homology_arm_end   \
          and my_allele.cassette_start      == targ_vec_allele.cassette_start     \
          and my_allele.cassette_end        == targ_vec_allele.cassette_end
        )
        errors.add( :targeting_vector_id, "targeting vector's molecular structure differs from ES cell's molecular structure" )
      end
    end

    # Set mirKO ikmc_project_ids to "mirKO#{self.allele_id}"
    def set_mirko_ikmc_project_id
      if ( self.ikmc_project_id.blank? or self.ikmc_project_id =~ /^mirko$/i ) and self.pipeline.name == "mirKO"
        self.ikmc_project_id = "mirKO#{ self.allele_id }"
      end
    end

    # Set the ES Cell Strain
   def set_and_check_strain
      self.strain = case self.parental_cell_line
      when /^JM8A/   then 'C57BL/6N-A<tm1Brd>/a'
      when /^JM8\.A/ then 'C57BL/6N-A<tm1Brd>/a'
      when /^JM8/    then 'C57BL/6N'
      when /^C2/     then 'C57BL/6N'
      when /^AB2/    then '129S7'
      when /^SI/     then '129S7'
      when 'VGB6'    then 'VGB6'
      else
        errors.add( :parental_cell_line, "The parental cell line '#{self.parental_cell_line}' is not recognised" )
      end
    end
end

# == Schema Information
# Schema version: 20110719134537
#
# Table name: es_cells
#
#  id                                    :integer(4)      not null, primary key
#  allele_id                             :integer(4)      not null
#  targeting_vector_id                   :integer(4)
#  parental_cell_line                    :string(255)
#  allele_symbol_superscript             :string(255)
#  name                                  :string(255)     not null
#  created_by                            :integer(4)
#  updated_by                            :integer(4)
#  created_at                            :datetime
#  updated_at                            :datetime
#  comment                               :string(255)
#  contact                               :string(255)
#  production_qc_five_prime_screen       :string(255)
#  distribution_qc_five_prime_sr_pcr     :string(255)
#  production_qc_three_prime_screen      :string(255)
#  distribution_qc_three_prime_sr_pcr    :string(255)
#  ikmc_project_id                       :string(255)
#  user_qc_map_test                      :string(255)
#  user_qc_karyotype                     :string(255)
#  user_qc_tv_backbone_assay             :string(255)
#  user_qc_loxp_confirmation             :string(255)
#  user_qc_southern_blot                 :string(255)
#  user_qc_loss_of_wt_allele             :string(255)
#  user_qc_neo_count_qpcr                :string(255)
#  user_qc_lacz_sr_pcr                   :string(255)
#  user_qc_mutant_specific_sr_pcr        :string(255)
#  user_qc_five_prime_cassette_integrity :string(255)
#  user_qc_neo_sr_pcr                    :string(255)
#  user_qc_five_prime_lr_pcr             :string(255)
#  user_qc_three_prime_lr_pcr            :string(255)
#  user_qc_comment                       :text
#  production_qc_loxp_screen             :string(255)
#  production_qc_loss_of_allele          :string(255)
#  production_qc_vector_integrity        :string(255)
#  distribution_qc_karyotype_low         :float
#  distribution_qc_karyotype_high        :float
#  distribution_qc_copy_number           :string(255)
#  distribution_qc_five_prime_lr_pcr     :string(255)
#  distribution_qc_three_prime_lr_pcr    :string(255)
#  distribution_qc_thawing               :string(255)
#  mgi_allele_id                         :string(50)
#  pipeline_id                           :integer(4)
#  report_to_public                      :boolean(1)      default(TRUE), not null
#  strain                                :string(25)
#
# Indexes
#
#  index_es_cells_on_name   (name) UNIQUE
#  es_cells_allele_id_fk    (allele_id)
#  es_cells_pipeline_id_fk  (pipeline_id)
#

