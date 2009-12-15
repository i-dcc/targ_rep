require 'test_helper'

class PipelineTest < ActiveSupport::TestCase
  setup do
    Factory.create( :pipeline )
    # Pipeline has been validated and saved successfully
  end
  
  should_have_many :targeting_vectors
  should_have_many :molecular_structures, :through => :targeting_vectors
  should_validate_uniqueness_of :name
  should_validate_presence_of :name
  
  context "Pipeline with empty attributes" do
    pipeline = Factory.build( :invalid_pipeline )
    should "not be saved" do
      assert( !pipeline.valid?, "Pipeline validates an empty entry" )
      assert( !pipeline.save, "Pipeline validates the creation of an empty entry" )
    end
  end
end
