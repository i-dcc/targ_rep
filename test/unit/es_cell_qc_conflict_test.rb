require 'test_helper'

class EsCellQcConflictTest < ActiveSupport::TestCase
  setup do
    Factory.create( :es_cell_qc_conflict )
  end
  
  should belong_to(:es_cell)
  
  should validate_presence_of(:qc_field)
  should validate_presence_of(:proposed_result)
  
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

