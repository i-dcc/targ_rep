class Pipeline < ActiveRecord::Base
  
  Pipeline.include_root_in_json = false
  
  ##
  ## Associations
  ##
  
  has_many :alleles, :class_name => "Allele", :foreign_key => "pipeline_id", :dependent => :destroy
  
  ##
  ## Validations
  ##
  
  validates_uniqueness_of :name, :message => 'This pipeline name has already been taken'
  validates_presence_of   :name
  
end

# == Schema Information
#
# Table name: pipelines
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)     not null
#  created_at :datetime
#  updated_at :datetime
#

