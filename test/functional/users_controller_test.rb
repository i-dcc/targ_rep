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
    assert_template :new
  end

  should "create user" do
    assert_difference('User.count') do
      post :create, :user => Factory.attributes_for( :user )
    end

    assert_redirected_to user_path( assigns(:user) )
  end

  should "not create user" do
    assert_no_difference('User.count') do
      post :create, :user => Factory.attributes_for( :invalid_user )
    end
    assert_template :new
  end

  should "show user" do
    UserSession.create( User.first )
    get :show
    assert_response :success
  end

  should "get edit" do
    get :edit, :id => User.first.id
    assert_response :success
  end

  should "update user" do
    UserSession.create(User.first)
    put :update, :user => { }
    assert_redirected_to users_path
  end

  should "not update user" do
    new_user = Factory.create( :user )
    UserSession.create(User.first)
    put :update, :user => { :username => new_user.username }
    assert_template :edit
  end
end
