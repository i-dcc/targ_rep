require 'test_helper'

class EsCellsControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :es_cell )
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:es_cells)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create es_cell" do
    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name                    => Factory.attributes_for( :es_cell )[:name],
        :targeting_vector_id     => EsCell.find(:first).targeting_vector_id,
        :molecular_structure_id  => EsCell.find(:first).molecular_structure_id
      }
    end

    assert_redirected_to es_cell_path(assigns(:es_cell))
  end

  test "should show es_cell" do
    get :show, :id => EsCell.find(:first).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => EsCell.find(:first).id
    assert_response :success
  end

  test "should update es_cell" do
    put :update, :id => EsCell.find(:first).id, :es_cell => Factory.attributes_for( :es_cell )
    assert_redirected_to es_cell_path(assigns(:es_cell))
  end

  test "should destroy es_cell" do
    assert_difference('EsCell.count', -1) do
      delete :destroy, :id => EsCell.find(:first).id
    end

    assert_redirected_to es_cells_path
  end
end
