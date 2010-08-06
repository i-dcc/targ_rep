class Pipeline < ActiveRecord::Base
  # Associations
  has_many :alleles,
    :class_name => "Allele",
    :foreign_key => "pipeline_id"
  
  has_many :es_cells, :through => :alleles, :uniq => true
  
  # Unique constraints
  validates_uniqueness_of :name, :message => 'This pipeline name has already been taken'
  
  # Data validation
  validates_presence_of :name
  
  Pipeline.include_root_in_json = false
end
