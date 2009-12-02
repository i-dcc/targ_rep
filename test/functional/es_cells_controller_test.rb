require 'test_helper'

class EsCellsControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :es_cell )
  end
  
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should not get new" do
    assert_raise(ActionController::UnknownAction) { get :new }
  end

  test "should create es_cell" do
    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name                    => Factory.attributes_for( :es_cell )[:name],
        :targeting_vector_id     => EsCell.find(:first).targeting_vector_id,
        :molecular_structure_id  => EsCell.find(:first).molecular_structure_id
      }
    end

    assert_response :success
  end

  test "should show es_cell" do
    get :show, :id => EsCell.find(:first).id
    assert_response :success
  end

  test "should not get edit" do
    assert_raise(ActionController::UnknownAction) { get :edit }
  end

  test "should update es_cell" do
    put :update, :id => EsCell.find(:first).id, :es_cell => Factory.attributes_for( :es_cell )
    assert_response :success
  end

  test "should destroy es_cell" do
    assert_difference('EsCell.count', -1) do
      delete :destroy, :id => EsCell.find(:first).id
    end
    assert_response :success
  end
end
