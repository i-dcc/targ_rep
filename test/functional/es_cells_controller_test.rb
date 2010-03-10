require 'test_helper'

class EsCellsControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :es_cell )
  end
  
  should "get index" do
    get :index
    assert_response :success
  end
  
  should "not get new" do
    assert_raise(ActionController::UnknownAction) { get :new }
  end
  
  should "create es_cell" do
    targ_vec = Factory.create( :targeting_vector )
    es_cell_attrs = Factory.attributes_for( :es_cell )
    
    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name                    => es_cell_attrs[:name],
        :parental_cell_line      => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id     => targ_vec.id,
        :molecular_structure_id  => targ_vec.molecular_structure_id
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

  should "update es_cell" do
    put :update, :id => EsCell.first.id, :es_cell => Factory.attributes_for( :es_cell )
    assert_response :success
  end
  
  should "not update es_cell" do
    another_escell = Factory.create( :es_cell )
    
    put :update, :id => EsCell.first.id, :es_cell => { :name => another_escell.name }
    assert_response 400
  end

  should "destroy es_cell" do
    assert_difference('EsCell.count', -1) do
      delete :destroy, :id => EsCell.first.id
    end
    assert_response :success
  end
end
