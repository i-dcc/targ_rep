require 'test_helper'

class MolecularStructuresControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :molecular_structure )
  end
  
  should "get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:molecular_structures)
  end

  should "get new" do
    get :new
    assert_response :success
  end

  should "create molecular structure" do
    assert_difference('MolecularStructure.count') do
      post :create,
      :molecular_structure => Factory.attributes_for( :molecular_structure )
    end

    assert_redirected_to molecular_structure_path(assigns(:molecular_structure))
  end
  
  should "not create molecular structure" do
    assert_no_difference('MolecularStructure.count') do
      post :create,
      :molecular_structure => Factory.attributes_for( :invalid_molecular_structure )
    end
    assert_template :new
  end

  should "show molecular structure" do
    get :show, :id => MolecularStructure.find(:first).to_param
    assert_response :success
  end

  should "get edit" do
    get :edit, :id => MolecularStructure.find(:first).to_param
    assert_response :success
  end

  should "update molecular structure" do
    put :update, :id => MolecularStructure.find(:first).to_param, 
      :molecular_structure => Factory.attributes_for( :molecular_structure )
    assert_redirected_to molecular_structure_path(assigns(:molecular_structure))
  end

  should "not update molecular structure" do
    put :update, :id => MolecularStructure.first.id,
      :molecular_structure => {
        :chromosome => "WRONG CHROMOSOME",
        :strand     => "WRONG STRAND"
      }
    assert_template :edit
  end

  should "destroy molecular_structure" do
    assert_difference('MolecularStructure.count', -1) do
      delete :destroy, :id => MolecularStructure.find(:first).to_param
    end

    assert_redirected_to molecular_structures_path
  end
end
