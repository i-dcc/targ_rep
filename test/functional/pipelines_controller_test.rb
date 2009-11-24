require 'test_helper'

class PipelinesControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user, :is_admin => true )
    Factory.create( :pipeline )
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pipelines)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pipeline" do
    assert_difference('Pipeline.count') do
      post :create, :pipeline => Factory.attributes_for( :pipeline )
    end

    assert_redirected_to pipeline_path(assigns(:pipeline))
  end

  test "should show pipeline" do
    get :show, :id => Pipeline.find(:first).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => Pipeline.find(:first).to_param
    assert_response :success
  end

  test "should update pipeline" do
    put :update, :id => Pipeline.find(:first).to_param, :pipeline => { }
    assert_redirected_to pipeline_path(assigns(:pipeline))
  end

  test "should destroy pipeline" do
    assert_difference('Pipeline.count', -1) do
      delete :destroy, :id => Pipeline.find(:first).to_param
    end

    assert_redirected_to pipelines_path
  end
end
