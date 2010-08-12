require 'test_helper'

class UserSessionsControllerTest < ActionController::TestCase
  should "get new" do
    get :new
    assert_response :success
  end

  test "should create user session" do
    post :create, :user_session => {
      :username => "the_dave",
      :password => "the_dave_is_here"
    }
    assert user_session = UserSession.find
    assert_equal users(:dave), user_session.user
  end
  
  should "not create a user session" do
    post :create, :user_session => {
      :login    => nil,
      :password => nil
    }
    assert_template :new
  end

  should "delete a session" do
    UserSession.create Factory.build( :user )
    delete :destroy
    assert_nil UserSession.find
    assert_redirected_to login_path
  end
end
