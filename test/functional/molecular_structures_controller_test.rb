require 'test_helper'

class MolecularStructuresControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :molecular_structure )
  end
  
  should "get index" do
    # html
    get :index, :format => "html"
    assert_response :success
    assert_not_nil assigns(:molecular_structures)
    
    # json
    get :index, :format => "json"
    assert_response :success
    
    # xml
    get :index, :format => "xml"
    assert_response :success
  end
  
  should "get new" do
    get :new
    assert_response :success
  end
  
  should "create molecular structure, targeting vector and es_cell" do
    mol_struct    = Factory.attributes_for( :molecular_structure )
    targ_vec1     = Factory.build( :targeting_vector )
    targ_vec2     = Factory.build( :targeting_vector )
    genbank_file  = Factory.build( :genbank_file )
    
    mol_struct_count  = MolecularStructure.all.count
    targ_vec_count    = TargetingVector.all.count
    es_cell_count     = EsCell.all.count
    unlinked_es_cells = EsCell.targeting_vector_id_null.count
    linked_es_cells   = EsCell.targeting_vector_id_not_null.count
    
    post :create, :molecular_structure => {
      :assembly            => mol_struct[:assembly],
      :mgi_accession_id    => mol_struct[:mgi_accession_id],
      :project_design_id   => mol_struct[:project_design_id],
      :chromosome          => mol_struct[:chromosome],
      :strand              => mol_struct[:strand],
      :design_type         => mol_struct[:design_type],
      :homology_arm_start  => mol_struct[:homology_arm_start],
      :homology_arm_end    => mol_struct[:homology_arm_end],
      :cassette_start      => mol_struct[:cassette_start],
      :cassette_end        => mol_struct[:cassette_end],
      
      :targeting_vectors => [
        # Targeting vector 1 with its ES cells
        {
          :pipeline_id         => targ_vec1[:pipeline_id],
          :ikmc_project_id     => targ_vec1[:ikmc_project_id],
          :name                => targ_vec1[:name],
          :intermediate_vector => targ_vec1[:intermediate_vector],
          :es_cells => [
            Factory.attributes_for( :es_cell ),
            Factory.attributes_for( :es_cell ),
            Factory.attributes_for( :es_cell )
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
      
      # ES Cells only related to molecular structure
      :es_cells => [
        { :name => Factory.attributes_for( :es_cell )[:name] },
        { :name => Factory.attributes_for( :es_cell )[:name] },
        { :name => Factory.attributes_for( :es_cell )[:name] }
      ],
      
      :genbank_file => {
        :escell_clone     => genbank_file[:escell_clone],
        :targeting_vector => genbank_file[:targeting_vector]
      }
    }
    assert_equal(
      mol_struct_count + 1, MolecularStructure.all.count,
      "Controller should have created 1 valid molecular structure."
    )
    assert_equal(
      targ_vec_count + 2, TargetingVector.all.count,
      "Controller should have created 2 valid targeting vectors."
    )
    assert_equal(
      es_cell_count + 6, EsCell.all.count,
      "Controller should have created 6 valid ES cells."
    )
    assert_equal(
      unlinked_es_cells + 3, EsCell.targeting_vector_id_null.count,
      "Controller should have created 3 more ES cells not linked to a targeting vector"
    )
    assert_equal(
      linked_es_cells + 3, EsCell.targeting_vector_id_not_null.count,
      "Controller should have created 3 more ES cells linked to a targeting vector"
    )
  end

  should "create molecular structure" do
    assert_difference('MolecularStructure.count') do
      post :create,
      :molecular_structure => Factory.attributes_for( :molecular_structure )
    end

    assert_redirected_to molecular_structure_path(assigns(:molecular_structure))
  end
  
  should "create molecular structure and genbank file" do
    mol_struct    = Factory.attributes_for( :molecular_structure )
    genbank_file  = Factory.build( :genbank_file )
    
    mol_struct_count    = MolecularStructure.count
    genbank_file_count  = GenbankFile.count
    
    post :create, :molecular_structure => {
      :assembly           => mol_struct[:assembly],
      :mgi_accession_id   => mol_struct[:mgi_accession_id],
      :chromosome         => mol_struct[:chromosome],
      :strand             => mol_struct[:strand],
      :design_type        => mol_struct[:design_type],
      :homology_arm_start => mol_struct[:homology_arm_start],
      :homology_arm_end   => mol_struct[:homology_arm_end],
      :cassette_start     => mol_struct[:cassette_start],
      :cassette_end       => mol_struct[:cassette_end],
      :genbank_file => {
        :escell_clone     => genbank_file[:escell_clone],
        :targeting_vector => genbank_file[:targeting_vector]
      }
    }
    assert_equal(
      mol_struct_count + 1, MolecularStructure.count,
      "Controller should have created 1 valid molecular structure."
    )
    assert_equal(
      genbank_file_count + 1, GenbankFile.count,
      "Controller should have create 1 more genbank file"
    )
  end
  
  should "not create molecular structure" do
    assert_no_difference('MolecularStructure.count') do
      post :create,
      :molecular_structure => Factory.attributes_for( :invalid_molecular_structure )
    end
    assert_template :new
  end

  should "show molecular structure" do
    mol_struct_id = MolecularStructure.find(:first).id
    
    # html
    get :show, :format => "html", :id => mol_struct_id
    assert_response :success, "should show molecular structure as html"
    
    # json
    get :show, :format => "json", :id => mol_struct_id
    assert_response :success, "should show molecular structure as json"
    
    # xml
    get :show, :format => "xml", :id => mol_struct_id
    assert_response :success, "should show molecular structure as xml"
  end

  should "get edit" do
    get :edit, :id => MolecularStructure.find(:first).to_param
    assert_response :success
  end

  should "update molecular structure" do
    put :update, :id => MolecularStructure.find(:first).to_param, 
      :molecular_structure => Factory.attributes_for( :molecular_structure )
    assert_redirected_to molecular_structure_path(assigns(:molecular_structure))
  end

  should "not update molecular structure" do
    put :update, :id => MolecularStructure.first.id,
      :molecular_structure => {
        :chromosome => "WRONG CHROMOSOME",
        :strand     => "WRONG STRAND"
      }
    assert_template :edit
  end

  should "destroy molecular_structure" do
    assert_difference('MolecularStructure.count', -1) do
      delete :destroy, :id => MolecularStructure.find(:first).to_param
    end

    assert_redirected_to molecular_structures_path
  end
end
