require 'test_helper'

class PipelinesControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user, :is_admin => true )
    Factory.create( :pipeline )
  end

  should "get index" do
    # html
    get :index, :format => "html"
    assert_response :success, "should get index as html"
    assert_not_nil assigns(:pipelines)
    
    # json
    get :index, :format => "json"
    assert_response :success, "should get index as json"
    
    # xml
    get :index, :format => "xml"
    assert_response :success, "should get index as xml"
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
    # html
    get :show, :id => Pipeline.first.id
    assert_response :success, "should show pipeline as html"
    
    # json
    get :show, :id => Pipeline.first.id, :format => "json"
    assert_response :success, "should show pipeline as json"
    
    # xml
    get :show, :id => Pipeline.first.id, :format => "xml"
    assert_response :success, "should show pipeline as xml"
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
