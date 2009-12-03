require 'test_helper'

class TargetingVectorTest < ActiveSupport::TestCase
  setup do
    Factory.create( :targeting_vector )
  end
  
  should_belong_to :pipeline
  should_belong_to :created_by, :updated_by

  should_validate_uniqueness_of :name, :scoped_to => :pipeline_id

  should_validate_presence_of :name
  should_validate_presence_of :pipeline_id
  should_validate_presence_of :molecular_structure_id
  should_validate_presence_of :ikmc_project_id
  
  context "Targeting vector with empty attributes" do
    targ_vec = Factory.build( :invalid_targeting_vector )
    should "not be saved" do
      assert( !targ_vec.valid?, "Targeting vector validates an empty entry" )
      assert( !targ_vec.save, "Targeting vector validates the creation of an empty entry" )
    end
  end
end
