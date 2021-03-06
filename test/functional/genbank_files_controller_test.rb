require 'test_helper'

class GenbankFilesControllerTest < ActionController::TestCase
  setup do
    user = Factory.create( :user )
    UserSession.create user
    Factory.create( :genbank_file )
  end
  
  teardown do
    session = UserSession.find
    session.destroy
  end
  
  should "not get index as html" do
    get :index, :format => "html"
    assert_response 406
  end
  
  should "not get index if allele_id is not given" do
    get :index, :format => "json"
    assert_response :unprocessable_entity
  end
  
  should "get index if allele_id is given" do
    get :index, :format => "json",
      :allele_id => GenbankFile.first.allele.id
    assert_response :success
  end

  should "not get new" do
    assert_raise(ActionController::UnknownAction) { get :new }
  end

  should "not get edit" do
    assert_raise(ActionController::UnknownAction) { get :edit }
  end

  should "create genbank_file" do
    allele = Factory.create( :allele )
    
    assert_difference('GenbankFile.count') do
      attrs = Factory.attributes_for( :genbank_file )
      post :create, :genbank_file => {
        :escell_clone     => attrs[:escell_clone],
        :targeting_vector => attrs[:targeting_vector],
        :allele_id        => allele.id
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
    put :update, :id => GenbankFile.first.id, :genbank_file => { :allele_id => nil }
    assert_response :unprocessable_entity
  end

  should "not allow us to delete a genbank_file when we're not the creator" do
    # Permission will be denied here because we are not deleting as the creator
    assert_no_difference('GenbankFile.count') do
      delete :destroy, :id => GenbankFile.first.id
    end
    assert_response 302
  end
  
  should "allow us to create and delete a genbank_file" do
    allele   = Factory.create( :allele )
    gb_attrs = Factory.attributes_for( :genbank_file )
    
    assert_difference('GenbankFile.count') do
      post :create, :genbank_file => {
        :escell_clone     => gb_attrs[:escell_clone],
        :targeting_vector => gb_attrs[:targeting_vector],
        :allele_id        => allele.id
      }
    end
    assert_response :success
    
    gb_file = GenbankFile.search( :allele_id => allele.id ).all.first
    gb_file.created_by = @request.session["user_credentials_id"]
    gb_file.save
    
    assert_difference('GenbankFile.count',-1) do
      delete :destroy, :id => gb_file.id
    end
    assert_response :success
  end
end
