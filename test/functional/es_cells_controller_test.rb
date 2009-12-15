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
    
    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name                    => Factory.attributes_for( :es_cell )[:name],
        :targeting_vector_id     => targ_vec.id,
        :molecular_structure_id  => targ_vec.molecular_structure.id
      }
    end
    assert_response :success
  end
  
  should "create es_cell, targeting_vector and molecular_structure" do
    mol_struct_count  = MolecularStructure.count
    targ_vec_count    = TargetingVector.count
    es_cell_count     = EsCell.count
    mol_struct_attrs  = Factory.attributes_for( :molecular_structure )
    targ_vec_attrs    = Factory.attributes_for( :targeting_vector )
    
    post :create, :es_cell => {
      :name                 => Factory.attributes_for( :es_cell )[:name],
      :targeting_vector     => {
        :name                 => targ_vec_attrs[:name],
        :intermediate_vector  => targ_vec_attrs[:intermediate_vector],
        :ikmc_project_id      => targ_vec_attrs[:ikmc_project_id],
        :parental_cell_line   => targ_vec_attrs[:parental_cell_line],
        :pipeline_id          => TargetingVector.find(:first).pipeline_id
      },
      :molecular_structure  => {
        :allele_symbol_superscript  => mol_struct_attrs[:allele_symbol_superscript],
        :mgi_accession_id           => mol_struct_attrs[:mgi_accession_id],
        :assembly                   => mol_struct_attrs[:assembly],
        :chromosome                 => mol_struct_attrs[:chromosome],
        :strand                     => mol_struct_attrs[:strand],
        :design_type                => mol_struct_attrs[:design_type],
        :homology_arm_start         => mol_struct_attrs[:homology_arm_start],
        :homology_arm_end           => mol_struct_attrs[:homology_arm_end],
        :cassette_start             => mol_struct_attrs[:cassette_start],
        :cassette_end               => mol_struct_attrs[:cassette_end]
      }
    }
    
    assert_not_equal(MolecularStructure.count, mol_struct_count)
    assert_not_equal(TargetingVector.count, targ_vec_count)
    assert_not_equal(EsCell.count, es_cell_count)
    assert_response :success
  end
  
  should "create es_cell and molecular_structure without targeting vector" do
    mol_struct_count  = MolecularStructure.count
    targ_vec_count    = TargetingVector.count
    es_cell_count     = EsCell.count
    mol_struct_attrs  = Factory.attributes_for( :molecular_structure )
    
    post :create, :es_cell => {
      :name                 => Factory.attributes_for( :es_cell )[:name],
      :molecular_structure  => {
        :allele_symbol_superscript  => mol_struct_attrs[:allele_symbol_superscript],
        :mgi_accession_id           => mol_struct_attrs[:mgi_accession_id],
        :assembly                   => mol_struct_attrs[:assembly],
        :chromosome                 => mol_struct_attrs[:chromosome],
        :strand                     => mol_struct_attrs[:strand],
        :design_type                => mol_struct_attrs[:design_type],
        :homology_arm_start         => mol_struct_attrs[:homology_arm_start],
        :homology_arm_end           => mol_struct_attrs[:homology_arm_end],
        :cassette_start             => mol_struct_attrs[:cassette_start],
        :cassette_end               => mol_struct_attrs[:cassette_end]
      }
    }
    
    assert_not_equal(MolecularStructure.count, mol_struct_count)
    assert_equal(TargetingVector.count, targ_vec_count)
    assert_not_equal(EsCell.count, es_cell_count)
    assert_response :success
  end
  
  should "create es_cell and molecular_structure, link to existing targeting_vector" do
    mol_struct_count  = MolecularStructure.count
    targ_vec_count    = TargetingVector.count
    es_cell_count     = EsCell.count
    targ_vec          = TargetingVector.first
    mol_struct        = targ_vec.molecular_structure
    
    post :create, :es_cell => {
      :name                 => Factory.attributes_for( :es_cell )[:name],
      :targeting_vector_id  => targ_vec.id,
      :molecular_structure  => {
        :allele_symbol_superscript  => mol_struct.allele_symbol_superscript,
        :mgi_accession_id           => mol_struct.mgi_accession_id,
        :assembly                   => mol_struct.assembly,
        :chromosome                 => mol_struct.chromosome,
        :strand                     => mol_struct.strand,
        :design_type                => mol_struct.design_type,
        :homology_arm_start         => mol_struct.homology_arm_start,
        :homology_arm_end           => mol_struct.homology_arm_end,
        :cassette_start             => mol_struct.cassette_start,
        :cassette_end               => mol_struct.cassette_end
      }
    }
    
    assert_not_equal(
      MolecularStructure.count, mol_struct_count, 
      "ES Cell controller should create molecular structure"
    )
    assert_equal(
      TargetingVector.count, targ_vec_count, 
      "ES Cell controller should not create targeting vector"
    )
    assert_not_equal(
      EsCell.count, es_cell_count,
      "ES Cell controller should create ES Cell"
    )
    assert_response :success
  end
  
  should "not create anything if given targeting_vector (from id) has not a similar molecular structure to the given one" do
    mol_struct_count  = MolecularStructure.count
    targ_vec_count    = TargetingVector.count
    es_cell_count     = EsCell.count
    targ_vec          = TargetingVector.first
    mol_struct_attrs  = Factory.attributes_for( :molecular_structure )
    
    post :create, :es_cell => {
      :name                 => Factory.attributes_for( :es_cell )[:name],
      :targeting_vector_id  => targ_vec.id,
      :molecular_structure  => {
        :allele_symbol_superscript  => mol_struct_attrs[:allele_symbol_superscript],
        :mgi_accession_id           => mol_struct_attrs[:mgi_accession_id],
        :assembly                   => mol_struct_attrs[:assembly],
        :chromosome                 => mol_struct_attrs[:chromosome],
        :strand                     => mol_struct_attrs[:strand],
        :design_type                => mol_struct_attrs[:design_type],
        :homology_arm_start         => mol_struct_attrs[:homology_arm_start],
        :homology_arm_end           => mol_struct_attrs[:homology_arm_end],
        :cassette_start             => mol_struct_attrs[:cassette_start],
        :cassette_end               => mol_struct_attrs[:cassette_end]
      }
    }
    
    assert_equal(
      MolecularStructure.count, mol_struct_count, 
      "ES Cell controller should not create molecular structure"
    )
    assert_equal(
      TargetingVector.count, targ_vec_count, 
      "ES Cell controller should not create targeting vector"
    )
    assert_equal(
      EsCell.count, es_cell_count,
      "ES Cell controller should not create ES Cell"
    )
    assert_response 400, "ES Cell controller should return a 400 reponse"
  end
  
  should "not create anything (from hash) if only es_cell is invalid" do
    mol_struct_count  = MolecularStructure.count
    targ_vec_count    = TargetingVector.count
    es_cell_count     = EsCell.count
    mol_struct_attrs  = Factory.attributes_for( :molecular_structure )
    targ_vec_attrs    = Factory.attributes_for( :targeting_vector )
    
    post :create, :es_cell => {
      :name                 => nil,
      :targeting_vector     => {
        :name                 => targ_vec_attrs[:name],
        :intermediate_vector  => targ_vec_attrs[:intermediate_vector],
        :ikmc_project_id      => targ_vec_attrs[:ikmc_project_id],
        :parental_cell_line   => targ_vec_attrs[:parental_cell_line],
        :pipeline_id          => TargetingVector.find(:first).pipeline_id
      },
      :molecular_structure  => {
        :allele_symbol_superscript  => mol_struct_attrs[:allele_symbol_superscript],
        :mgi_accession_id           => mol_struct_attrs[:mgi_accession_id],
        :assembly                   => mol_struct_attrs[:assembly],
        :chromosome                 => mol_struct_attrs[:chromosome],
        :strand                     => mol_struct_attrs[:strand],
        :design_type                => mol_struct_attrs[:design_type],
        :homology_arm_start         => mol_struct_attrs[:homology_arm_start],
        :homology_arm_end           => mol_struct_attrs[:homology_arm_end],
        :cassette_start             => mol_struct_attrs[:cassette_start],
        :cassette_end               => mol_struct_attrs[:cassette_end]
      }
    }
    
    assert_equal(
      MolecularStructure.count, mol_struct_count,
      "ES Cell controller should not create molecular structure"
    )
    assert_equal(
      TargetingVector.count, targ_vec_count,
      "ES Cell controller should not create targeting vector"
    )
    assert_equal(
      EsCell.count, es_cell_count,
      "ES Cell controller should not create ES Cell"
    )
    assert_response 400
  end
  
  should "not create anything (from ID) if only es_cell is invalid" do
    mol_struct_count  = MolecularStructure.count
    targ_vec_count    = TargetingVector.count
    es_cell_count     = EsCell.count
    targ_vec          = TargetingVector.first
    mol_struct        = targ_vec.molecular_structure
    
    post :create, :es_cell => {
      :name                     => nil,
      :targeting_vector_id      => targ_vec.id,
      :molecular_structure_id   => mol_struct.id
    }
    
    assert_equal(
      MolecularStructure.count, mol_struct_count,
      "ES Cell controller should not create molecular structure"
    )
    assert_equal(
      TargetingVector.count, targ_vec_count,
      "ES Cell controller should not create targeting vector"
    )
    assert_equal(
      EsCell.count, es_cell_count,
      "ES Cell controller should not create ES Cell"
    )
    assert_response 400
  end
  
  should "not create anything if only targeting_vector is invalid" do
    mol_struct_count  = MolecularStructure.count
    targ_vec_count    = TargetingVector.count
    es_cell_count     = EsCell.count
    mol_struct_attrs  = Factory.attributes_for( :molecular_structure )
    targ_vec_attrs    = Factory.attributes_for( :targeting_vector )
    
    post :create, :es_cell => {
      :name                 => Factory.attributes_for( :es_cell )[:name],
      :targeting_vector     => Factory.attributes_for( :invalid_targeting_vector ),
      :molecular_structure  => {
        :allele_symbol_superscript  => mol_struct_attrs[:allele_symbol_superscript],
        :mgi_accession_id           => mol_struct_attrs[:mgi_accession_id],
        :assembly                   => mol_struct_attrs[:assembly],
        :chromosome                 => mol_struct_attrs[:chromosome],
        :strand                     => mol_struct_attrs[:strand],
        :design_type                => mol_struct_attrs[:design_type],
        :homology_arm_start         => mol_struct_attrs[:homology_arm_start],
        :homology_arm_end           => mol_struct_attrs[:homology_arm_end],
        :cassette_start             => mol_struct_attrs[:cassette_start],
        :cassette_end               => mol_struct_attrs[:cassette_end]
      }
    }
    
    assert_equal(
      MolecularStructure.count, mol_struct_count,
      "ES Cell controller should not create molecular structure"
    )
    assert_equal(
      TargetingVector.count, targ_vec_count,
      "ES Cell controller should not create targeting vector"
    )
    assert_equal(
      EsCell.count, es_cell_count,
      "ES Cell controller should not create ES Cell"
    )
    assert_response 400
  end
  
  should "not create anything if only molecular_structure is invalid" do
    mol_struct_count  = MolecularStructure.count
    targ_vec_count    = TargetingVector.count
    es_cell_count     = EsCell.count
    targ_vec_attrs    = Factory.attributes_for( :targeting_vector )
    
    post :create, :es_cell => {
      :name                 => Factory.attributes_for( :es_cell )[:name],
      :targeting_vector     => {
        :name                 => targ_vec_attrs[:name],
        :intermediate_vector  => targ_vec_attrs[:intermediate_vector],
        :ikmc_project_id      => targ_vec_attrs[:ikmc_project_id],
        :parental_cell_line   => targ_vec_attrs[:parental_cell_line],
        :pipeline_id          => TargetingVector.find(:first).pipeline_id
      },
      :molecular_structure  => Factory.attributes_for( :invalid_molecular_structure )
    }
    
    assert_equal(
      MolecularStructure.count, mol_struct_count,
      "ES Cell controller should not create molecular structure"
    )
    assert_equal(
      TargetingVector.count, targ_vec_count,
      "ES Cell controller should not create targeting vector"
    )
    assert_equal(
      EsCell.count, es_cell_count,
      "ES Cell controller should not create ES Cell"
    )
    assert_response 400
  end
  
  should "not create anything if both molecular_structure id and hash are given" do
    mol_struct_count  = MolecularStructure.count
    targ_vec_count    = TargetingVector.count
    es_cell_count     = EsCell.count
    mol_struct_attrs  = Factory.attributes_for( :molecular_structure )
    targ_vec_attrs    = Factory.attributes_for( :targeting_vector )
    
    post :create, :es_cell => {
      :name                 => Factory.attributes_for( :es_cell )[:name],
      :targeting_vector     => {
        :name                 => targ_vec_attrs[:name],
        :intermediate_vector  => targ_vec_attrs[:intermediate_vector],
        :ikmc_project_id      => targ_vec_attrs[:ikmc_project_id],
        :parental_cell_line   => targ_vec_attrs[:parental_cell_line],
        :pipeline_id          => TargetingVector.find(:first).pipeline_id
      },
      :molecular_structure_id => Factory.attributes_for( :molecular_structure )[:id],
      :molecular_structure  => {
        :allele_symbol_superscript  => mol_struct_attrs[:allele_symbol_superscript],
        :mgi_accession_id           => mol_struct_attrs[:mgi_accession_id],
        :assembly                   => mol_struct_attrs[:assembly],
        :chromosome                 => mol_struct_attrs[:chromosome],
        :strand                     => mol_struct_attrs[:strand],
        :design_type                => mol_struct_attrs[:design_type],
        :homology_arm_start         => mol_struct_attrs[:homology_arm_start],
        :homology_arm_end           => mol_struct_attrs[:homology_arm_end],
        :cassette_start             => mol_struct_attrs[:cassette_start],
        :cassette_end               => mol_struct_attrs[:cassette_end]
      }
    }
    
    assert_equal(
      MolecularStructure.count, mol_struct_count,
      "ES Cell controller should not create molecular structure"
    )
    assert_equal(
      TargetingVector.count, targ_vec_count,
      "ES Cell controller should not create targeting vector"
    )
    assert_equal(
      EsCell.count, es_cell_count,
      "ES Cell controller should not create ES Cell"
    )
    assert_response 400
  end
  
  should "not create anything if both targeting_vector id and hash are given" do
    mol_struct_count  = MolecularStructure.count
    targ_vec_count    = TargetingVector.count
    es_cell_count     = EsCell.count
    mol_struct_attrs  = Factory.attributes_for( :molecular_structure )
    targ_vec_attrs    = Factory.attributes_for( :targeting_vector )
    
    post :create, :es_cell => {
      :name                 => Factory.attributes_for( :es_cell )[:name],
      :targeting_vector_id  => Factory.attributes_for( :targeting_vector )[:id],
      :targeting_vector     => {
        :name                 => targ_vec_attrs[:name],
        :intermediate_vector  => targ_vec_attrs[:intermediate_vector],
        :ikmc_project_id      => targ_vec_attrs[:ikmc_project_id],
        :parental_cell_line   => targ_vec_attrs[:parental_cell_line],
        :pipeline_id          => TargetingVector.find(:first).pipeline_id
      },
      :molecular_structure  => {
        :allele_symbol_superscript  => mol_struct_attrs[:allele_symbol_superscript],
        :mgi_accession_id           => mol_struct_attrs[:mgi_accession_id],
        :assembly                   => mol_struct_attrs[:assembly],
        :chromosome                 => mol_struct_attrs[:chromosome],
        :strand                     => mol_struct_attrs[:strand],
        :design_type                => mol_struct_attrs[:design_type],
        :homology_arm_start         => mol_struct_attrs[:homology_arm_start],
        :homology_arm_end           => mol_struct_attrs[:homology_arm_end],
        :cassette_start             => mol_struct_attrs[:cassette_start],
        :cassette_end               => mol_struct_attrs[:cassette_end]
      }
    }
    
    assert_equal(
      MolecularStructure.count, mol_struct_count,
      "ES Cell controller should not create molecular structure"
    )
    assert_equal(
      TargetingVector.count, targ_vec_count,
      "ES Cell controller should not create targeting vector"
    )
    assert_equal(
      EsCell.count, es_cell_count,
      "ES Cell controller should not create ES Cell"
    )
    assert_response 400
  end
  
  should "show es_cell" do
    es_cell_id = EsCell.find(:first).id
    
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
    put :update, :id => EsCell.find(:first).id, :es_cell => Factory.attributes_for( :es_cell )
    assert_response :success
  end
  
  should "not update es_cell" do
    another_escell = Factory.create( :es_cell )
    
    put :update, :id => EsCell.first.id, :es_cell => {
      :name => another_escell.name
    }
    assert_response :unprocessable_entity
  end

  should "destroy es_cell" do
    assert_difference('EsCell.count', -1) do
      delete :destroy, :id => EsCell.find(:first).id
    end
    assert_response :success
  end
end
