require 'test_helper'

class MolecularStructuresControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :molecular_structure )
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:molecular_structures)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create molecular_structure" do
    assert_difference('MolecularStructure.count') do
      post :create, :molecular_structure => Factory.attributes_for( :molecular_structure )
    end

    assert_redirected_to molecular_structure_path(assigns(:molecular_structure))
  end

  test "should show molecular_structure" do
    get :show, :id => MolecularStructure.find(:first).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => MolecularStructure.find(:first).to_param
    assert_response :success
  end

  test "should update molecular_structure" do
    put :update, :id => MolecularStructure.find(:first).to_param, :molecular_structure => { }
    assert_redirected_to molecular_structure_path(assigns(:molecular_structure))
  end

  test "should destroy molecular_structure" do
    assert_difference('MolecularStructure.count', -1) do
      delete :destroy, :id => MolecularStructure.find(:first).to_param
    end

    assert_redirected_to molecular_structures_path
  end
end
