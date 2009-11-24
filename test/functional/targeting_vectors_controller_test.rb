require 'test_helper'

class TargetingVectorsControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :targeting_vector )
  end
  
  should "get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:targeting_vectors)
  end

  should "get new" do
    get :new
    assert_response :success
  end

  should "create targeting vector" do
    assert_difference('TargetingVector.count') do
      attrs = Factory.attributes_for( :targeting_vector )
      post :create, :targeting_vector => {
        :name                   => attrs[:name],
        :intermediate_vector    => attrs[:intermediate_vector],
        :ikmc_project_id        => attrs[:ikmc_project_id],
        :parental_cell_line     => attrs[:parental_cell_line],
        :pipeline_id            => TargetingVector.find(:first).pipeline_id,
        :molecular_structure_id => TargetingVector.find(:first).molecular_structure_id
      }
    end

    assert_redirected_to targeting_vector_path(assigns(:targeting_vector))
  end

  should "show targeting_vector" do
    get :show, :id => TargetingVector.find(:first).to_param
    assert_response :success
  end

  should "get edit" do
    get :edit, :id => TargetingVector.find(:first).to_param
    assert_response :success
  end

  should "update targeting_vector" do
    put :update, :id => TargetingVector.find(:first).to_param, :targeting_vector => Factory.attributes_for( :targeting_vector )
    assert_redirected_to targeting_vector_path(assigns(:targeting_vector))
  end

  should "destroy targeting_vector" do
    assert_difference('TargetingVector.count', -1) do
      delete :destroy, :id => TargetingVector.find(:first).to_param
    end

    assert_redirected_to targeting_vectors_path
  end
end
