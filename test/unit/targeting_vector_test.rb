require 'test_helper'

class TargetingVectorTest < ActiveSupport::TestCase
  setup do
    Factory.create( :targeting_vector )
  end
  
  should belong_to(:created_by)
  should belong_to(:updated_by)

  should validate_uniqueness_of(:name).with_message('This Targeting Vector name has already been taken')

  should validate_presence_of(:name)
  should validate_presence_of(:allele_id)
  
  context "Targeting vector with empty attributes" do
    targ_vec = Factory.build( :invalid_targeting_vector )
    should "not be saved" do
      assert( !targ_vec.valid?, "Targeting vector validates an empty entry" )
      assert( !targ_vec.save, "Targeting vector validates the creation of an empty entry" )
    end
  end
end
