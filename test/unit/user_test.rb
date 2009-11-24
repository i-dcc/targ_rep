require 'test_helper'

class UserTest < Test::Unit::TestCase
  context "User" do
    context "with valid attributes" do
      should "be saved" do
        assert(Factory.create( :user ), "User does not create a valid entry")
      end
    end
    
    context "with empty attributes" do
      user = Factory.build(:invalid_user)
      should "not be saved" do
        assert( !user.valid?, "User validates an empty entry" )
        assert( !user.save, "User validates the creation of an empty entry" )
      end
    end
  end
end
