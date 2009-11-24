require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user, :is_admin => true )
  end
  
  should "get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  should "get new" do
    get :new
    assert_response :success
  end

  should "create user" do
    assert_difference('User.count') do
      post :create, :user => Factory.attributes_for( :user )
    end

    assert_redirected_to user_path(assigns(:user))
  end

  should "show user" do
    get :show, :id => User.find(:first).to_param
    assert_response :success
  end

  should "get edit" do
    get :edit, :id => User.find(:first).to_param
    assert_response :success
  end

  should "update user" do
    put :update, :id => User.find(:first).to_param, :user => { }
    assert_redirected_to user_path(assigns(:user))
  end
end
