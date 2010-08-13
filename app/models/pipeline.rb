class Pipeline < ActiveRecord::Base
  
  Pipeline.include_root_in_json = false
  
  ##
  ## Associations
  ##
  
  has_many :alleles, :class_name => "Allele", :foreign_key => "pipeline_id"
  
  ##
  ## Validations
  ##
  
  validates_uniqueness_of :name, :message => 'This pipeline name has already been taken'
  validates_presence_of   :name
  
end
