require 'test_helper'

class AllelesControllerTest < ActionController::TestCase
  # Note: to make sure url_for works in a functional test,
  # we need to include the two files below
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  
  setup do
    user = Factory.create( :user )
    UserSession.create user
    Factory.create( :allele )
  end
  
  teardown do
    session = UserSession.find
    session.destroy
  end
  
  should "allow us to GET /index" do
    # html
    get :index, :format => "html"
    assert_response :success
    assert_not_nil assigns(:alleles)
    
    # json
    get :index, :format => "json"
    assert_response :success
    
    # xml
    get :index, :format => "xml"
    assert_response :success
  end
  
  should "allow us to GET /new" do
    get :new
    assert_response :success
  end
  
  should "allow us to GET /edit" do
    get :edit, :id => Allele.find(:first).to_param
    assert_response :success
  end
  
  should "allow us to create allele, targeting vector, es cell and genbank files" do
    mol_struct    = Factory.attributes_for( :allele )
    targ_vec1     = Factory.build( :targeting_vector )
    targ_vec2     = Factory.build( :targeting_vector )
    genbank_file  = Factory.build( :genbank_file )
    
    mol_struct_count  = Allele.all.count
    targ_vec_count    = TargetingVector.all.count
    es_cell_count     = EsCell.all.count
    unlinked_es_cells = EsCell.targeting_vector_id_null.count
    linked_es_cells   = EsCell.targeting_vector_id_not_null.count
    
    post :create, :allele => {
      :assembly           => mol_struct[:assembly],
      :mgi_accession_id   => mol_struct[:mgi_accession_id],
      :project_design_id  => mol_struct[:project_design_id],
      :chromosome         => mol_struct[:chromosome],
      :strand             => mol_struct[:strand],
      :design_type        => mol_struct[:design_type],
      :homology_arm_start => mol_struct[:homology_arm_start],
      :homology_arm_end   => mol_struct[:homology_arm_end],
      :cassette_start     => mol_struct[:cassette_start],
      :cassette_end       => mol_struct[:cassette_end],
      :cassette_type      => mol_struct[:cassette_type],
      :cassette           => mol_struct[:cassette],
      
      :targeting_vectors => [
        # Targeting vector 1 with its ES cells
        {
          :pipeline_id         => targ_vec1[:pipeline_id],
          :ikmc_project_id     => targ_vec1[:ikmc_project_id],
          :name                => targ_vec1[:name],
          :intermediate_vector => targ_vec1[:intermediate_vector],
          :es_cells => [
            Factory.attributes_for( :es_cell, :ikmc_project_id => targ_vec1[:ikmc_project_id], :pipeline_id => targ_vec1[:pipeline_id] ),
            Factory.attributes_for( :es_cell, :ikmc_project_id => targ_vec1[:ikmc_project_id], :pipeline_id => targ_vec1[:pipeline_id] ),
            Factory.attributes_for( :es_cell, :ikmc_project_id => targ_vec1[:ikmc_project_id], :pipeline_id => targ_vec1[:pipeline_id] )
          ]
        },
        
        # Targeting vector 2 without ES Cells
        {
          :pipeline_id         => targ_vec2[:pipeline_id],
          :ikmc_project_id     => targ_vec2[:ikmc_project_id],
          :name                => targ_vec2[:name],
          :intermediate_vector => targ_vec2[:intermediate_vector]     
        }
      ],
      
      # ES Cells only related to allele
      :es_cells => [
        { :name => Factory.attributes_for( :es_cell )[:name], :pipeline_id => targ_vec1[:pipeline_id] },
        { :name => Factory.attributes_for( :es_cell )[:name], :pipeline_id => targ_vec1[:pipeline_id] },
        { :name => Factory.attributes_for( :es_cell )[:name], :pipeline_id => targ_vec1[:pipeline_id] }
      ],
      
      :genbank_file => {
        :escell_clone     => genbank_file[:escell_clone],
        :targeting_vector => genbank_file[:targeting_vector]
      }
    }
    
    assert_equal( mol_struct_count + 1, Allele.all.count, "Controller should have created 1 valid allele." )
    assert_equal( targ_vec_count + 2, TargetingVector.all.count, "Controller should have created 2 valid targeting vectors." )
    assert_equal( es_cell_count + 6, EsCell.all.count, "Controller should have created 6 valid ES cells." )
    assert_equal( unlinked_es_cells + 3, EsCell.targeting_vector_id_null.count, "Controller should have created 3 more ES cells not linked to a targeting vector" )
    assert_equal( linked_es_cells + 3, EsCell.targeting_vector_id_not_null.count, "Controller should have created 3 more ES cells linked to a targeting vector" )
  end

  should "allow us to create, update and delete a allele we made" do
    allele_attrs = Factory.attributes_for( :allele )
    
    # CREATE
    assert_difference('Allele.count') do
      post :create, :allele => allele_attrs
    end
    assert_redirected_to allele_path(assigns(:allele))
    
    created_allele = Allele.search( :mgi_accession_id => allele_attrs[:mgi_accession_id] ).last
    created_allele.created_by = @request.session["user_credentials_id"]
    created_allele.save
    
    # UPDATE
    put :update, { :id => created_allele.id, :allele => Factory.attributes_for( :allele ) }
    assert_redirected_to allele_path(assigns(:allele))
    
    # DELETE
    back_url = url_for( :controller => 'alleles', :action => 'index' )
    @request.env['HTTP_REFERER'] = back_url
    assert_difference('Allele.count', -1) do
      delete :destroy, :id => created_allele.id
    end
    assert_redirected_to back_url
  end
  
  should "allow us to create a allele and genbank file" do
    mol_struct    = Factory.attributes_for( :allele )
    genbank_file  = Factory.attributes_for( :genbank_file )
    
    mol_struct_count    = Allele.count
    genbank_file_count  = GenbankFile.count
    
    post :create, :allele => {
      :assembly           => mol_struct[:assembly],
      :mgi_accession_id   => mol_struct[:mgi_accession_id],
      :chromosome         => mol_struct[:chromosome],
      :strand             => mol_struct[:strand],
      :design_type        => mol_struct[:design_type],
      :homology_arm_start => mol_struct[:homology_arm_start],
      :homology_arm_end   => mol_struct[:homology_arm_end],
      :cassette_start     => mol_struct[:cassette_start],
      :cassette_end       => mol_struct[:cassette_end],
      :cassette_type      => mol_struct[:cassette_type],
      :cassette           => mol_struct[:cassette],
      :genbank_file => {
        :escell_clone     => genbank_file[:escell_clone],
        :targeting_vector => genbank_file[:targeting_vector]
      }
    }

    assert_true assigns["allele"].valid?, assigns["allele"].errors.full_messages.join(', ')
    assert_redirected_to assigns["allele"], "Not redirected to the new allele"

    assert_equal( mol_struct_count + 1, Allele.count, "Controller should have created 1 valid allele." )
    assert_equal( genbank_file_count + 1, GenbankFile.count, "Controller should have created 1 more genbank file" )
  end

  should "not create genbank file database entries if the genbank file arguments are empty" do
    mol_struct = Factory.attributes_for( :allele )
    
    mol_struct_count    = Allele.count
    genbank_file_count  = GenbankFile.count
    
    post :create, :allele => {
      :assembly           => mol_struct[:assembly],
      :mgi_accession_id   => mol_struct[:mgi_accession_id],
      :chromosome         => mol_struct[:chromosome],
      :strand             => mol_struct[:strand],
      :design_type        => mol_struct[:design_type],
      :homology_arm_start => mol_struct[:homology_arm_start],
      :homology_arm_end   => mol_struct[:homology_arm_end],
      :cassette_start     => mol_struct[:cassette_start],
      :cassette_end       => mol_struct[:cassette_end],
      :cassette_type      => mol_struct[:cassette_type],
      :cassette           => mol_struct[:cassette],
      :genbank_file       => { :escell_clone => '', :targeting_vector => '' }
    }
    
    assert_equal( mol_struct_count + 1, Allele.count, "Controller should have created 1 valid allele." )
    assert_equal( genbank_file_count, GenbankFile.count, "Controller should not have created any genbank file" )
  end

  should "not create genbank file database entries if the genbank file arguments are nil" do
    mol_struct = Factory.attributes_for( :allele )

    mol_struct_count    = Allele.count
    genbank_file_count  = GenbankFile.count

    post :create, :allele => {
      :assembly           => mol_struct[:assembly],
      :mgi_accession_id   => mol_struct[:mgi_accession_id],
      :chromosome         => mol_struct[:chromosome],
      :strand             => mol_struct[:strand],
      :design_type        => mol_struct[:design_type],
      :homology_arm_start => mol_struct[:homology_arm_start],
      :homology_arm_end   => mol_struct[:homology_arm_end],
      :cassette_start     => mol_struct[:cassette_start],
      :cassette_end       => mol_struct[:cassette_end],
      :cassette_type      => mol_struct[:cassette_type],
      :cassette           => mol_struct[:cassette],
      :genbank_file       => { :escell_clone => nil, :targeting_vector => nil }
    }
    
    assert_equal( mol_struct_count + 1, Allele.count, "Controller should have created 1 valid allele." )
    assert_equal( genbank_file_count, GenbankFile.count, "Controller should not have created any genbank file" )
  end
  
  should "not create an invalid allele" do
    assert_no_difference('Allele.count') do
      post :create,
      :allele => Factory.attributes_for( :invalid_allele )
    end
    assert_template :new
  end

  should "show an allele" do
    allele_id = Allele.find(:first).id
    
    # html
    get :show, :format => "html", :id => allele_id
    assert_response :success, "should show allele as html"
    
    # json
    get :show, :format => "json", :id => allele_id
    assert_response :success, "should show allele as json"
    
    # xml
    get :show, :format => "xml", :id => allele_id
    assert_response :success, "should show allele as xml"
  end

  should "find and return allele when searching by marker_symbol" do
    mol_struct = Factory.create( :allele, :mgi_accession_id => 'MGI:105369')
    
    get :index, { :marker_symbol => 'cbx1' }
    assert_response :success
    assert_select 'tbody tr', 1, "HTML <table> should only have one row/result."
    assert_select 'td', { :text => 'MGI:105369' }
  end

  should "not allow us to update a allele with invalid parameters" do
    mol_struct_attrs = Factory.attributes_for( :allele )
    
    # CREATE a valid Molecular Structure
    assert_difference('Allele.count') do
      post :create, :allele => mol_struct_attrs
    end
    assert_redirected_to allele_path(assigns(:allele))
    
    created_mol_struct = Allele.search( :mgi_accession_id => mol_struct_attrs[:mgi_accession_id] ).first
    
    # UPDATE - should fail
    put :update, :id => created_mol_struct.id,
      :allele => {
        :chromosome => "WRONG CHROMOSOME",
        :strand     => "WRONG STRAND"
      }
    assert_template :edit
  end

  should "not allow us to delete a allele when we're not the creator" do
    # Permission will be denied here because we are not deleting with the owner
    assert_no_difference('Allele.count') do
      delete :destroy, :id => Allele.first.id
    end
    assert_response 302
  end
  
  should "return 404 if we try to request something to do with a genbank file that doesn't exist" do
    allele_without_gb = Factory.create( :allele )
    
    [:escell_clone_genbank_file,:targeting_vector_genbank_file,:allele_image,:vector_image].each do |route|
      get route, :id => allele_without_gb.id
      assert_response 404
    end
  end
end
