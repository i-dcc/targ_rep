require 'test_helper'

class UserTest < Test::Unit::TestCase
  context "User" do
    context "with valid attributes" do
      should "be saved" do
        User.first.delete
        user = Factory.build( :user )
        assert( user.valid?, "User does not validate a valid entry")
        assert( user.save, "User does not save a valid entry")
      end
    end
    
    context "with empty attributes" do
      user = Factory.build( :invalid_user )
      should "not be saved" do
        assert( !user.valid?, "User validates an empty entry" )
        assert( !user.save, "User validates the creation of an empty entry" )
      end
    end
  end
end
