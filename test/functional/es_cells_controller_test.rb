require 'test_helper'

class EsCellsControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user ) # A different user for each test
    Factory.create(:es_cell)
  end
  
  should "get index" do
    get :index
    assert_response :success
  end
  
  should "not get new" do
    assert_raise(ActionController::UnknownAction) { get :new }
  end
  
  should "create, update and delete es_cell when user is allowed" do
    es_cell_attrs = Factory.attributes_for( :es_cell )
    
    # As each test is run with a different user,
    # we need the user to create, update and delete the same allele 
    # so that the permissions for updating and deleting are granted
    
    # CREATE
    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name                    => es_cell_attrs[:name],
        :parental_cell_line      => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id     => EsCell.first.targeting_vector_id,
        :molecular_structure_id  => EsCell.first.molecular_structure_id
      }
    end
    assert_response :success
    
    created_es_cell = EsCell.search(:name => es_cell_attrs[:name]).first
    
    # UPDATE
    put :update, :id => created_es_cell.id, :es_cell => Factory.attributes_for( :es_cell )
    assert_response :success
    
    # DELETE
    assert_difference('EsCell.count', -1) do
      delete :destroy, :id => created_es_cell.id
    end
    assert_response :success
  end
  
  should "create without providing a targeting vector" do
    es_cell_attrs = Factory.attributes_for( :es_cell )
    
    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name                    => es_cell_attrs[:name],
        :parental_cell_line      => es_cell_attrs[:parental_cell_line],
        :molecular_structure_id  => EsCell.first.molecular_structure_id
      }
    end
    assert_response :success
  end
  
  should "show es_cell" do
    es_cell_id = EsCell.first.id
    
    get :show, :format => "html", :id => es_cell_id
    assert_response 406, "Controller should not allow HTML display"
    
    get :show, :format => "json", :id => es_cell_id
    assert_response :success, "Controller does not allow JSON display"
    
    get :show, :format => "xml", :id => es_cell_id
    assert_response :success, "Controller does not allow XML display"
  end

  should "not get edit" do
    assert_raise(ActionController::UnknownAction) { get :edit }
  end

  should "not update es_cell" do
    es_cell_attrs   = Factory.attributes_for( :es_cell )
    another_escell  = Factory.create( :es_cell )
    
    # CREATE a valid ES Cell
    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name                    => es_cell_attrs[:name],
        :parental_cell_line      => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id     => EsCell.first.targeting_vector_id,
        :molecular_structure_id  => EsCell.first.molecular_structure_id
      }
    end
    assert_response :success
    
    created_es_cell = EsCell.search(:name => es_cell_attrs[:name]).first
    
    # UPDATE - should fail but not with permission denied
    put :update, :id => created_es_cell.id, :es_cell => { :name => another_escell.name }
    assert_response 400
  end

  should "not update es_cell when permission is denied" do
    # Permission will be denied here because we are not updating with the owner
    put :update, :id => EsCell.first.id, :es_cell => { :name => 'new name' }
    assert_response 302
  end

  should "not destroy es_cell when permission is denied" do
    # Permission will be denied here because we are not deleting with the owner
    assert_no_difference('EsCell.count') do
      delete :destroy, :id => EsCell.first.id
    end
    assert_response 302
  end
end
