require 'test_helper'

class EsCellQcConflictTest < ActiveSupport::TestCase
  setup do
    Factory.create( :es_cell_qc_conflict )
  end
  
  should belong_to(:created_by)
  should belong_to(:updated_by)
  should belong_to(:es_cell)
  
  should validate_presence_of(:qc_field)
  should validate_presence_of(:proposed_result)
  
end
