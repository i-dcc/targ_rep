require 'test_helper'

class UserTest < Test::Unit::TestCase
  context "User" do
    context "with valid attributes" do
      should "be saved" do
        user = Factory.build( :user )
        assert( user.valid?, "User does not validate a valid entry")
        assert( user.save, "User does not save a valid entry")
        assert( user.delete, "User cannot be deleted after use")
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

# == Schema Information
#
# Table name: users
#
#  id                 :integer(4)      not null, primary key
#  username           :string(255)     not null
#  email              :string(255)
#  crypted_password   :string(255)
#  password_salt      :string(255)
#  persistence_token  :string(255)
#  last_login_at      :datetime
#  is_admin           :boolean(1)      default(FALSE), not null
#  created_at         :datetime
#  updated_at         :datetime
#  login_count        :integer(4)      default(0), not null
#  failed_login_count :integer(4)      default(0), not null
#  last_request_at    :datetime
#  current_login_at   :datetime
#  current_login_ip   :string(255)
#  last_login_ip      :string(255)
#

