class EsCellQcConflict < ActiveRecord::Base
  acts_as_audited
  stampable

  attr_accessor :nested

  belongs_to :es_cell, :class_name => 'EsCell', :foreign_key => 'es_cell_id', :validate => true

  validates_presence_of :qc_field
  validates_presence_of :proposed_result

  # Stamp the current QC result for the ES Cell if it's not already noted...
  before_create do |conflict|
    if conflict.current_result.nil? or conflict.current_result.empty?
      conflict.current_result = conflict.es_cell.attributes[ conflict.qc_field.to_s ]
    end
  end

end

# == Schema Information
#
# Table name: es_cell_qc_conflicts
#
#  id              :integer(4)      not null, primary key
#  es_cell_id      :integer(4)
#  qc_field        :string(255)     not null
#  current_result  :string(255)     not null
#  proposed_result :string(255)     not null
#  comment         :text
#  created_by      :integer(4)
#  updated_by      :integer(4)
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  es_cell_qc_conflicts_es_cell_id_fk  (es_cell_id)
#

