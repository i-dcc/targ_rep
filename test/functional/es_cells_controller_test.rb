require 'test_helper'

class EsCellsControllerTest < ActionController::TestCase
  setup do
    user = Factory.create( :user )
    UserSession.create user
    Factory.create(:es_cell)
  end
  
  teardown do
    session = UserSession.find
    session.destroy
  end
  
  should "allow us to GET /index" do
    get :index
    assert_response :success
  end
  
  should "not allow us to GET /new" do
    assert_raise(ActionController::UnknownAction) { get :new }
  end
  
  should "not allow us to GET /edit without a cell id" do
    assert_raise(ActionController::UnknownAction) { get :edit }
  end
  
  should "allow us to create, update and delete an es_cell we made" do
    pipeline      = Factory.create( :pipeline )
    es_cell_attrs = Factory.attributes_for( :es_cell )
    
    # CREATE
    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name                => es_cell_attrs[:name],
        :parental_cell_line  => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id => EsCell.first.targeting_vector_id,
        :allele_id           => EsCell.first.allele_id,
        :mgi_allele_id       => es_cell_attrs[:mgi_allele_id],
        :pipeline_id         => pipeline.id
      }
    end
    assert_response :success, "Could not create ES Cell"
    
    created_es_cell = EsCell.search(:name => es_cell_attrs[:name]).last
    created_es_cell.created_by = @request.session["user_credentials_id"]
    created_es_cell.save
    
    # UPDATE
    put :update, :id => created_es_cell.id, :es_cell => { :name => 'new name' }
    assert_response :success, "Could not update ES Cell"
    
    # DELETE
    assert_difference('EsCell.count', -1) do
      delete :destroy, :id => created_es_cell.id
    end
    assert_response :success, "Could not delete ES Cell"
  end
    
  should "allow us to create without providing a targeting vector" do
    pipeline      = Factory.create( :pipeline )
    es_cell_attrs = Factory.attributes_for( :es_cell )
    
    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name               => es_cell_attrs[:name],
        :parental_cell_line => es_cell_attrs[:parental_cell_line],
        :allele_id          => EsCell.first.allele_id,
        :mgi_allele_id      => es_cell_attrs[:mgi_allele_id],
        :pipeline_id        => pipeline.id
      }
    end
    assert_response :success
  end
  
  should "show an es_cell" do
    es_cell_id = EsCell.first.id
    
    get :show, :format => "html", :id => es_cell_id
    assert_response 406, "Controller should not allow HTML display"
    
    get :show, :format => "json", :id => es_cell_id
    assert_response :success, "Controller does not allow JSON display"
    
    get :show, :format => "xml", :id => es_cell_id
    assert_response :success, "Controller does not allow XML display"
  end

  should "not allow us to rename an existing cell to the same name as another cell" do
    pipeline        = Factory.create( :pipeline )
    es_cell_attrs   = Factory.attributes_for( :es_cell )
    another_escell  = Factory.create( :es_cell )
    
    # CREATE a valid ES Cell
    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name                => es_cell_attrs[:name],
        :parental_cell_line  => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id => EsCell.first.targeting_vector_id,
        :allele_id           => EsCell.first.allele_id,
        :mgi_allele_id       => es_cell_attrs[:mgi_allele_id],
        :pipeline_id         => pipeline.id
      }
    end
    assert_response :success
    
    created_es_cell = EsCell.search(:name => es_cell_attrs[:name]).first
    
    # UPDATE - should fail as we're trying to enter a duplicate name
    put :update, :id => created_es_cell.id, :es_cell => { :name => another_escell.name }
    assert_response 400
  end

  should "not allow us to delete an es_cell when we're not the creator" do
    # Permission will be denied here because we are not deleting as the creator
    assert_no_difference('EsCell.count') do
      delete :destroy, :id => EsCell.first.id
    end
    assert_response 302
  end
  
  should "allow us to reparent an es_cell if we need to" do
    es_cell        = Factory.create( :es_cell, { :targeting_vector => nil } )
    current_parent = es_cell.allele
    new_parent     = Factory.create( :allele )
    
    assert_equal( es_cell.allele_id, current_parent.id, "WTF? The es_cell doesn't have the correct allele_id in the first place..." )
    
    put :update, :id => es_cell.id, :es_cell => { :allele_id => new_parent.id }
    assert_response :success
    
    es_cell = EsCell.find(es_cell.id)
    
    assert_not_equal( es_cell.allele_id, current_parent.id, "Ooops, we haven't switched parents..." )
    assert_equal( es_cell.allele_id, new_parent.id, "Ooops, we haven't switched parents..." )
  end
  
  should "allow us to interact with the /bulk_edit view" do
    get :bulk_edit
    assert_response :success, "Unable to open /es_cells/bulk_edit"
    
    post :bulk_edit, :es_cell_names => EsCell.first.name
    assert_response :success, "Unable to open /es_cells/bulk_edit with an es_cell_names parameter"
  end
end
