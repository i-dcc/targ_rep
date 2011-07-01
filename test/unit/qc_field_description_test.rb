require 'test_helper'

class QcFieldDescriptionTest < ActiveSupport::TestCase
  setup do
    Factory.create( :qc_field_description )
  end
  
  should validate_presence_of(:qc_field)
  should validate_presence_of(:description)
end

