require 'test_helper'

class GenbankFilesControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :genbank_file )
  end
  
  should "not get index" do
    assert_raise(ActionController::UnknownAction) { get :index }
  end

  should "not get new" do
    assert_raise(ActionController::UnknownAction) { get :new }
  end

  should "not get edit" do
    assert_raise(ActionController::UnknownAction) { get :edit }
  end

  should "create genbank_file" do
    assert_difference('GenbankFile.count') do
      attrs = Factory.attributes_for( :genbank_file )
      post :create, :genbank_file => {
        :escell_clone           => attrs[:escell_clone],
        :targeting_vector       => attrs[:targeting_vector],
        :molecular_structure_id => GenbankFile.first.molecular_structure.id
      }
    end
    
    assert_response :success
  end
  
  should "not create genbank file" do
    assert_no_difference('GenbankFile.count') do
      post :create, :genbank_file => Factory.attributes_for( :invalid_genbank_file )
    end
    
    assert_response :unprocessable_entity
  end

  should "show genbank_file" do
    get :show, :id => GenbankFile.first.id
    
    assert_response :success
  end

  should "update genbank_file" do
    attrs = Factory.attributes_for( :genbank_file )
    put :update, :id => GenbankFile.first.id, 
      :genbank_file => {
        :escell_clone     => attrs[:escell_clone],
        :targeting_vector => attrs[:targeting_vector]
      }
    
    assert_response :success
  end

  should "not update genbank_file" do
    put :update, :id => GenbankFile.first.id, 
      :genbank_file => {
        :molecular_structure_id => nil
      }

    assert_response :unprocessable_entity
  end

  should "destroy genbank_file" do
    assert_difference('GenbankFile.count', -1) do
      delete :destroy, :id => GenbankFile.first.id
    end
    assert_response :success
  end
end
