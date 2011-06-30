class TargetingVector < ActiveRecord::Base
  acts_as_audited
  stampable
  
  attr_accessor :nested
  
  ##
  ## Associations
  ##
  
  belongs_to :allele, :class_name => 'Allele', :foreign_key => 'allele_id', :validate => true
    
  has_many :es_cells, :class_name => "EsCell", :foreign_key => "targeting_vector_id", :dependent => :destroy
  
  accepts_nested_attributes_for :es_cells, :allow_destroy => true
  
  ##
  ## Validations
  ##
  
  validates_uniqueness_of :name, :message => 'This Targeting Vector name has already been taken'
  
  validates_presence_of :allele_id, :on => :save, :unless => :nested
  validates_presence_of :name
  
  ##
  ## Filters
  ##
  
  before_save :set_mirko_ikmc_project_id
  
  ##
  ## Methods
  ##
  
  public
    def to_json( options = {} )
      TargetingVector.include_root_in_json = false
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
    # Set mirKO ikmc_project_ids to "mirKO#{self.allele_id}"
    def set_mirko_ikmc_project_id
      if self.ikmc_project_id.nil? and self.allele.pipeline.name == "mirKO"
        self.ikmc_project_id = "mirKO#{ self.allele_id }"
      end
    end
end

# == Schema Information
#
# Table name: targeting_vectors
#
#  id                  :integer(4)      not null, primary key
#  allele_id           :integer(4)      not null
#  ikmc_project_id     :string(255)
#  name                :string(255)     not null
#  intermediate_vector :string(255)
#  created_by          :integer(4)
#  updated_by          :integer(4)
#  created_at          :datetime
#  updated_at          :datetime
#  display             :boolean(1)      default(TRUE)
#

