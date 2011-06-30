require 'test_helper'

class TargetingVectorTest < ActiveSupport::TestCase
  setup do
    Factory.create( :targeting_vector )
  end
  
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
      allele   = Factory.create( :allele, :pipeline => pipeline )
      targ_vec = Factory.create( :targeting_vector, :allele => allele, :ikmc_project_id => nil )
      assert( targ_vec.valid? )
      assert_equal( "mirKO#{ allele.id }", targ_vec.ikmc_project_id )
    end
  end
end

# == Schema Information
#
# Table name: targeting_vectors
#
#  id                  :integer(4)      not null, primary key
#  allele_id           :integer(4)      not null
#  ikmc_project_id     :string(255)
#  name                :string(255)     not null
#  intermediate_vector :string(255)
#  created_by          :integer(4)
#  updated_by          :integer(4)
#  created_at          :datetime
#  updated_at          :datetime
#  display             :boolean(1)      default(TRUE)
#

