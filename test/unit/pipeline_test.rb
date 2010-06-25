require 'test_helper'

class PipelineTest < ActiveSupport::TestCase
  setup do
    Factory.create( :pipeline )
    # Pipeline has been validated and saved successfully
  end
  
  should have_many(:molecular_structures)
  should validate_uniqueness_of(:name).with_message('This pipeline name has already been taken')
  should validate_presence_of(:name)
  
  context "Pipeline with empty attributes" do
    pipeline = Factory.build( :invalid_pipeline )
    should "not be saved" do
      assert( !pipeline.valid?, "Pipeline validates an empty entry" )
      assert( !pipeline.save, "Pipeline validates the creation of an empty entry" )
    end
  end
end
