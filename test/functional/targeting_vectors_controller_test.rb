require 'test_helper'

class TargetingVectorsControllerTest < ActionController::TestCase
  setup do
    user = Factory.create( :user )
    UserSession.create user
    Factory.create( :targeting_vector )
  end
  
  teardown do
    session = UserSession.find
    session.destroy
  end
  
  should "not allow us to GET /edit" do
    assert_raise(ActionController::UnknownAction) { get :edit }
  end
  
  should "not allow us to GET /new" do
    assert_raise(ActionController::UnknownAction) { get :new }
  end
  
  should "allow us to GET /index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:targeting_vectors)
  end
  
  should "allow us to create, update and delete a targeting vector we made" do
    # CREATE
    pipeline       = Factory.create( :pipeline )
    targ_vec_attrs = Factory.attributes_for( :targeting_vector )
    assert_difference('TargetingVector.count') do
      post :create, :targeting_vector => {
        :name        => targ_vec_attrs[:name],
        :allele_id   => TargetingVector.first.allele_id,
        :pipeline_id => pipeline.id
      }
    end
    assert_response :success
    
    created_targ_vec = TargetingVector.search( :name => targ_vec_attrs[:name] ).last
    created_targ_vec.created_by = @request.session["user_credentials_id"]
    created_targ_vec.save
    
    # UPDATE
    attrs = Factory.attributes_for( :targeting_vector )
    put :update, :id => created_targ_vec.id, :targeting_vector => { :name => 'new name' }
    assert_response :success
    
    # DELETE
    assert_difference('TargetingVector.count', -1) do
      delete :destroy, :id => created_targ_vec.id
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
  
  should "not allow us to update a targeting_vector with invalid parameters" do
    pipeline         = Factory.create( :pipeline )
    targ_vec_attrs   = Factory.attributes_for( :targeting_vector )
    another_targ_vec = Factory.create( :targeting_vector )
    
    # CREATE a valid Targeting Vector
    targ_vec_attrs = Factory.attributes_for( :targeting_vector )
    assert_difference('TargetingVector.count') do
      post :create, :targeting_vector => {
        :name        => targ_vec_attrs[:name],
        :allele_id   => TargetingVector.first.allele_id,
        :pipeline_id => pipeline.id
      }
    end
    assert_response :success
    
    created_targ_vec = TargetingVector.search( :name => targ_vec_attrs[:name] ).first
    
    # UPDATE - should fail as the name is already taken
    put :update, :id => created_targ_vec.id, :targeting_vector => { :name => another_targ_vec.name }
    assert_response :unprocessable_entity
    
    # UPDATE - should fail as we're not allowed a nil allele_id
    put :update, :id => created_targ_vec.id, :targeting_vector => { :allele_id => nil }
    assert_response :unprocessable_entity
  end
  
  should "not allow us to delete a targeting_vector when we are not the creator" do
    # Permission will be denied here because we are not deleting with the creator
    assert_no_difference('TargetingVector.count') do
      delete :destroy, :id => TargetingVector.first.id
    end
    assert_response 302
  end
end
