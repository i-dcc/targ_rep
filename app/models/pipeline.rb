class Pipeline < ActiveRecord::Base

  NON_REPORTABLE = ['EUCOMM GT']

  Pipeline.include_root_in_json = false

  ##
  ## Associations
  ##

  has_many :targeting_vectors,  :class_name => "TargetingVector", :foreign_key => "pipeline_id", :dependent => :destroy
  has_many :es_cells,           :class_name => "EsCell",          :foreign_key => "pipeline_id", :dependent => :destroy

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
# Indexes
#
#  index_pipelines_on_name  (name)
#

