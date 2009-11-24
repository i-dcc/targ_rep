require 'test_helper'

class GenbankFilesControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :genbank_file )
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:genbank_files)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create genbank_file" do
    assert_difference('GenbankFile.count') do
      post :create, :genbank_file => Factory.attributes_for( :genbank_file )
    end

    assert_redirected_to genbank_file_path(assigns(:genbank_file))
  end

  test "should show genbank_file" do
    get :show, :id => GenbankFile.find(:first).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => GenbankFile.find(:first).to_param
    assert_response :success
  end

  test "should update genbank_file" do
    put :update, :id => GenbankFile.find(:first).to_param, :genbank_file => { }
    assert_redirected_to genbank_file_path(assigns(:genbank_file))
  end

  test "should destroy genbank_file" do
    assert_difference('GenbankFile.count', -1) do
      delete :destroy, :id => GenbankFile.find(:first).to_param
    end

    assert_redirected_to genbank_files_path
  end
end
