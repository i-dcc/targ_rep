require 'test_helper'

class TargetingVectorTest < ActiveSupport::TestCase
  setup do
    Factory.create( :targeting_vector )
  end
  
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

  context "A Targeting Vector" do
    setup do
      @pipeline = Factory.create( :pipeline, :id => 5 )
      @allele   = Factory.create( :allele, :pipeline => @pipeline )
      @targ_vec = Factory.create( :targeting_vector, :allele => @allele, :ikmc_project_id => nil )
    end

    should "create a valid allele" do
      assert @allele
      assert_equal 5, @allele.pipeline_id
    end

    should "create a valid targeting vector" do
      assert @targ_vec
      assert_equal 5, @targ_vec.allele.pipeline_id
      assert_equal "mirKO#{ @allele.id }", @targ_vec.ikmc_project_id
    end
  end
end
