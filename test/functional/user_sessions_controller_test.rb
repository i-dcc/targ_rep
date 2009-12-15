require 'test_helper'

class UserSessionsControllerTest < ActionController::TestCase
  should "get new" do
    get :new
    assert_response :success
  end

  should "create user session" do
    user = User.first || Factory.build( :user )
    post :create, :user_session => {
      :username => user.username,
      :password => "secret"
    }
    assert_equal 'Successfully logged in.', flash[:notice]
    assert( @user_session = UserSession.find, "User session has not been created" )
    assert_equal( user, @user_session.user, "User is unknown" )
  end
  
  should "not create user session" do
    post :create, :user_session => {
      :login    => nil,
      :password => nil
    }
    assert_template :new
  end

  should "delete session" do
    UserSession.create Factory.build( :user )
    delete :destroy
    assert_nil UserSession.find
    assert_redirected_to login_path
  end
end
