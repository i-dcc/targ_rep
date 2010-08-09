class EsCellQcConflict < ActiveRecord::Base
  acts_as_audited
  
  attr_accessor :nested
  
  belongs_to :created_by, :class_name => 'User',   :foreign_key => 'created_by'
  belongs_to :updated_by, :class_name => 'User',   :foreign_key => 'updated_by'
  belongs_to :es_cell,    :class_name => 'EsCell', :foreign_key => 'es_cell_id', :validate => true
  
  validates_presence_of :qc_field
  validates_presence_of :proposed_result
  
  # Stamp the current QC result for the ES Cell if it's not already noted...
  before_create do |conflict|
    if conflict.current_result.nil? or conflict.current_result.empty?
      conflict.current_result = conflict.es_cell.attributes[ conflict.qc_field.to_s ]
    end
  end
  
end
