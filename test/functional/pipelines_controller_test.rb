require 'test_helper'

class PipelinesControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user, :is_admin => true )
    Factory.create( :pipeline )
  end

  should "get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pipelines)
  end

  should "get new" do
    get :new
    assert_response :success
  end

  should "create pipeline" do
    assert_difference('Pipeline.count') do
      post :create, :pipeline => Factory.attributes_for( :pipeline )
    end

    assert_redirected_to pipeline_path(assigns(:pipeline))
  end
  
  should "not create pipeline" do
    assert_no_difference('Pipeline.count') do
      post :create, :pipeline => Factory.attributes_for( :invalid_pipeline )
    end
  end

  should "show pipeline" do
    get :show, :id => Pipeline.find(:first).to_param
    assert_response :success
  end

  should "get edit" do
    get :edit, :id => Pipeline.find(:first).to_param
    assert_response :success
  end

  should "update pipeline" do
    put :update, :id => Pipeline.first.id, 
      :pipeline => Factory.attributes_for( :pipeline )
    assert_redirected_to pipeline_path(assigns(:pipeline))
  end
  
  should "not update pipeline" do
    put :update, :id => Pipeline.first.id,
      :pipeline => {
        :name => nil
      }
  end

  should "destroy pipeline" do
    assert_difference('Pipeline.count', -1) do
      delete :destroy, :id => Pipeline.find(:first).to_param
    end

    assert_redirected_to pipelines_path
  end
end
