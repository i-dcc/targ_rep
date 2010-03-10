require 'test_helper'

class TargetingVectorsControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :targeting_vector )
  end
  
  should "not get edit" do
    assert_raise(ActionController::UnknownAction) { get :edit }
  end
  
  should "not get new" do
    assert_raise(ActionController::UnknownAction) { get :new }
  end
  
  should "get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:targeting_vectors)
  end
  
  should "create targeting vector" do
    assert_difference('TargetingVector.count') do
      post :create, :targeting_vector => {
        :name                   => Factory.attributes_for( :targeting_vector )[:name],
        :pipeline_id            => TargetingVector.first.pipeline_id,
        :molecular_structure_id => TargetingVector.first.molecular_structure_id
      }
    end
    
    assert_response :success
  end
  
  should "show targeting vector" do
    targ_vec_id = TargetingVector.find(:first).to_param
    
    get :show, :format => "html", :id => targ_vec_id
    assert_response 406, "Controller should not allow HTML display"
    
    get :show, :format => "json", :id => targ_vec_id
    assert_response :success, "Controller does not allow JSON display"
    
    get :show, :format => "xml", :id => targ_vec_id
    assert_response :success, "Controller does not allow XML display"
  end
  
  should "update targeting_vector" do
    attrs = Factory.attributes_for( :targeting_vector )
    put :update, :id => TargetingVector.first.id,
      :targeting_vector => {
        :ikmc_project_id     => attrs[:ikmc_project_id],
        :name                => attrs[:name],
        :intermediate_vector => attrs[:intermediate_vector]
      }
    assert_response :success
  end

  should "not update targeting vector" do
    another_targ_vec = Factory.create( :targeting_vector )

    put :update, :id => TargetingVector.first.id, :targeting_vector => {
      :pipeline_id  => another_targ_vec.pipeline.id,
      :name         => another_targ_vec.name
    }
    assert_response :unprocessable_entity
    
    put :update, :id => TargetingVector.first.id, :targeting_vector => {
      :pipeline_id            => nil,
      :molecular_structure_id => nil
    }
    assert_response :unprocessable_entity
  end
  
  should "destroy targeting_vector" do
    assert_difference('TargetingVector.count', -1) do
      delete :destroy, :id => TargetingVector.first
    end
    assert_response :success
  end
end
