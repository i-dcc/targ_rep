require 'test_helper'

class GenbankFilesControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :genbank_file )
  end
  
  test "should not get index" do
    assert_raise(ActionController::UnknownAction) { get :index }
  end

  test "should not get new" do
    assert_raise(ActionController::UnknownAction) { get :new }
  end

  test "should not get edit" do
    assert_raise(ActionController::UnknownAction) { get :edit }
  end

  test "should create genbank_file" do
    assert_difference('GenbankFile.count') do
      attrs = Factory.attributes_for( :genbank_file )
      post :create, :genbank_file => {
        :escell_clone           => attrs[:escell_clone],
        :targeting_vector       => attrs[:targeting_vector],
        :molecular_structure_id => GenbankFile.find(:first).molecular_structure_id
      }
    end
    assert_response :success
  end

  test "should show genbank_file" do
    get :show, :id => GenbankFile.find(:first).to_param
    assert_response :success
  end

  test "should update genbank_file" do
    put :update, :id => GenbankFile.find(:first).to_param, :genbank_file => Factory.attributes_for( :genbank_file )
    assert_response :success
  end

  test "should destroy genbank_file" do
    assert_difference('GenbankFile.count', -1) do
      delete :destroy, :id => GenbankFile.find(:first).to_param
    end
    assert_response :success
  end
end
