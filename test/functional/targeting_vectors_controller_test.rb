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
  
  should "create, update and delete targeting vector" do
    # CREATE
    targ_vec_attrs = Factory.attributes_for( :targeting_vector )
    assert_difference('TargetingVector.count') do
      post :create, :targeting_vector => {
        :name                   => targ_vec_attrs[:name],
        :molecular_structure_id => TargetingVector.first.molecular_structure_id
      }
    end
    assert_response :success
    
    created_targ_vec = TargetingVector.search( :name => targ_vec_attrs[:name] ).first
    
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
  
  should "not update targeting_vector" do
    targ_vec_attrs   = Factory.attributes_for( :targeting_vector )
    another_targ_vec = Factory.create( :targeting_vector )
    
    # CREATE a valid Targeting Vector
    targ_vec_attrs = Factory.attributes_for( :targeting_vector )
    assert_difference('TargetingVector.count') do
      post :create, :targeting_vector => {
        :name                   => targ_vec_attrs[:name],
        :molecular_structure_id => TargetingVector.first.molecular_structure_id
      }
    end
    assert_response :success
    
    created_targ_vec = TargetingVector.search( :name => targ_vec_attrs[:name] ).first
    
    # UPDATE - should fail but not with permission denied
    put :update, :id => created_targ_vec.id, :targeting_vector => { :name => another_targ_vec.name }
    assert_response :unprocessable_entity
    put :update, :id => created_targ_vec.id, :targeting_vector => { :molecular_structure_id => nil }
    assert_response :unprocessable_entity
  end
  
  should "not update targeting_vector when permission is denied" do
    # Permission will be denied here because we are not updating with the owner
    put :update, :id => TargetingVector.first.id, :targeting_vector => { :name => 'new name' }
    assert_response 302
  end

  should "not destroy targeting_vector when permission is denied" do
    # Permission will be denied here because we are not deleting with the owner
    assert_no_difference('TargetingVector.count') do
      delete :destroy, :id => TargetingVector.first.id
    end
    assert_response 302
  end
end
