require 'test_helper'

class TargetingVectorTest < ActiveSupport::TestCase
  setup do
    Factory.create( :targeting_vector )
  end

  should belong_to(:pipeline)
  should belong_to(:allele)

  should have_many(:es_cells)

  should validate_uniqueness_of(:name).with_message('This Targeting Vector name has already been taken')

  should validate_presence_of(:name)
  should validate_presence_of(:allele_id)

  context "Targeting vector" do
    should "not be saved if it has empty attributes" do
      targ_vec = Factory.build( :invalid_targeting_vector )
      assert( !targ_vec.valid?, "Targeting vector validates an empty entry" )
      assert( !targ_vec.save, "Targeting vector validates the creation of an empty entry" )
    end

    should "set mirKO ikmc_project_ids to 'mirKO' + self.allele_id" do
      pipeline = Factory.create( :pipeline, :name => "mirKO" )
      allele   = Factory.create( :allele )
      targ_vec = Factory.create( :targeting_vector, :pipeline => pipeline, :allele => allele, :ikmc_project_id => nil )
      assert( targ_vec.valid? )
      assert_equal( "mirKO#{ allele.id }", targ_vec.ikmc_project_id )

      targ_vec2 = Factory.create( :targeting_vector, :pipeline => pipeline, :allele => allele, :ikmc_project_id => 'mirKO' )
      assert_equal( "mirKO#{ allele.id }", targ_vec2.ikmc_project_id )
    end
  end
end

