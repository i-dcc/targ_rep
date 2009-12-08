require 'test_helper'

class TargetingVectorsControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :targeting_vector )
  end
  
  should "not get edit" do
    assert_raise(ActionController::UnknownAction) { get :edit }
  end
  
  should "not get new" do
    assert_raise(ActionController::UnknownAction) { get :new }
  end
  
  should "get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:targeting_vectors)
  end
  
  should "create targeting vector" do
    assert_difference('TargetingVector.count') do
      attrs = Factory.attributes_for( :targeting_vector )
      post :create, :targeting_vector => {
        :name                   => attrs[:name],
        :intermediate_vector    => attrs[:intermediate_vector],
        :ikmc_project_id        => attrs[:ikmc_project_id],
        :parental_cell_line     => attrs[:parental_cell_line],
        :pipeline_id            => TargetingVector.find(:first).pipeline_id,
        :molecular_structure_id => TargetingVector.find(:first).molecular_structure_id
      }
    end
    assert_response :success
  end
  
  should "create targeting vector and molecular structure" do
    targ_vec_count    = TargetingVector.count
    mol_struct_count  = MolecularStructure.count
    mol_struct_attrs  = Factory.attributes_for( :molecular_structure )
    targ_vec_attrs    = Factory.attributes_for( :targeting_vector )
    
    post :create, :targeting_vector => {
      :name                   => targ_vec_attrs[:name],
      :intermediate_vector    => targ_vec_attrs[:intermediate_vector],
      :ikmc_project_id        => targ_vec_attrs[:ikmc_project_id],
      :parental_cell_line     => targ_vec_attrs[:parental_cell_line],
      :pipeline_id            => TargetingVector.find(:first).pipeline_id,
      :molecular_structure    => {
        :mgi_accession_id           => mol_struct_attrs[:mgi_accession_id],
        :assembly                   => mol_struct_attrs[:assembly],
        :chromosome                 => mol_struct_attrs[:chromosome],
        :strand                     => mol_struct_attrs[:strand],
        :design_type                => mol_struct_attrs[:design_type],
        :homology_arm_start         => mol_struct_attrs[:homology_arm_start],
        :homology_arm_end           => mol_struct_attrs[:homology_arm_end],
        :cassette_start             => mol_struct_attrs[:cassette_start],
        :cassette_end               => mol_struct_attrs[:cassette_end],
        :allele_symbol_superscript  => mol_struct_attrs[:allele_symbol_superscript]
      }
    }
    
    assert_not_equal(MolecularStructure.count, mol_struct_count, "controller does not allow creation of valid molecular structure and targeting vector")
    assert_not_equal(TargetingVector.count, targ_vec_count, "controller does not allow creation of valid molecular structure and targeting vector")
    assert_response :success
  end
  
  should "not create anything if both molecular structure hash and id are given" do
    mol_struct_count  = MolecularStructure.count
    targ_vec_count    = TargetingVector.count
    mol_struct_attrs  = Factory.attributes_for( :molecular_structure )
    targ_vec_attrs    = Factory.attributes_for( :targeting_vector )
    
    post :create, :targeting_vector => {
      :name                   => targ_vec_attrs[:name],
      :intermediate_vector    => targ_vec_attrs[:intermediate_vector],
      :ikmc_project_id        => targ_vec_attrs[:ikmc_project_id],
      :parental_cell_line     => targ_vec_attrs[:parental_cell_line],
      :pipeline_id            => TargetingVector.find(:first).pipeline_id,
      :molecular_structure_id => TargetingVector.find(:first).molecular_structure_id,
      :molecular_structure    => {
        :mgi_accession_id           => mol_struct_attrs[:mgi_accession_id],
        :assembly                   => mol_struct_attrs[:assembly],
        :chromosome                 => mol_struct_attrs[:chromosome],
        :strand                     => mol_struct_attrs[:strand],
        :design_type                => mol_struct_attrs[:design_type],
        :homology_arm_start         => mol_struct_attrs[:homology_arm_start],
        :homology_arm_end           => mol_struct_attrs[:homology_arm_end],
        :cassette_start             => mol_struct_attrs[:cassette_start],
        :cassette_end               => mol_struct_attrs[:cassette_end],
        :allele_symbol_superscript  => mol_struct_attrs[:allele_symbol_superscript]
      }
    }
    
    assert_equal(MolecularStructure.count, mol_struct_count, "controller allows creation of a molecular structure that goes with an invalid targeting vector")
    assert_equal(TargetingVector.count, targ_vec_count, "controller allows creation of a targeting vector related to both new and existing molecular structures")
    assert_response 400
  end
  
  should "not create anything if molecular_structure is invalid" do
    assert_no_difference('TargetingVector.count') do
      attrs = Factory.attributes_for( :targeting_vector )
      post :create, :targeting_vector => {
        :name                   => attrs[:name],
        :intermediate_vector    => attrs[:intermediate_vector],
        :ikmc_project_id        => attrs[:ikmc_project_id],
        :parental_cell_line     => attrs[:parental_cell_line],
        :pipeline_id            => TargetingVector.find(:first).pipeline_id,
        :molecular_structure    => Factory.attributes_for( :invalid_molecular_structure )
      }
    end
    assert_response 400
  end
  
  should "not create anything if targeting_vector is invalid" do
    mol_struct_count  = MolecularStructure.count
    targ_vec_count    = TargetingVector.count
    
    attrs = Factory.attributes_for( :molecular_structure )
    post :create, :targeting_vector => {
      :molecular_structure    => {
        :mgi_accession_id           => attrs[:mgi_accession_id],
        :assembly                   => attrs[:assembly],
        :chromosome                 => attrs[:chromosome],
        :strand                     => attrs[:strand],
        :design_type                => attrs[:design_type],
        :homology_arm_start         => attrs[:homology_arm_start],
        :homology_arm_end           => attrs[:homology_arm_end],
        :cassette_start             => attrs[:cassette_start],
        :cassette_end               => attrs[:cassette_end],
        :allele_symbol_superscript  => attrs[:allele_symbol_superscript]
      }
    }
    
    assert_equal(
      MolecularStructure.count, mol_struct_count, 
      "Targeting vector controller allows creation of a molecular structure that goes with a wrong targeting vector"
    )
    assert_equal(
      TargetingVector.count, targ_vec_count, 
      "Targeting vector controller allows creation of an invalid targeting vector"
    )
    assert_response 400
  end
  
  should "show targeting_vector" do
    get :show, :id => TargetingVector.find(:first).to_param
    assert_response :success
  end
  
  should "update targeting_vector" do
    attrs = Factory.attributes_for( :targeting_vector )
    put :update, :id => TargetingVector.first.id,
      :targeting_vector => {
        :ikmc_project_id     => attrs[:ikmc_project_id],
        :name                => attrs[:name],
        :intermediate_vector => attrs[:intermediate_vector],
        :parental_cell_line  => attrs[:parental_cell_line]
      }
    assert_response :success
  end

  should "not update targeting vector" do
    another_targ_vec = Factory.create( :targeting_vector )

    put :update, :id => TargetingVector.first.id, :targeting_vector => {
      :pipeline_id  => another_targ_vec.pipeline.id,
      :name         => another_targ_vec.name
    }
    assert_response :unprocessable_entity
    
    put :update, :id => TargetingVector.first.id, :targeting_vector => {
      :pipeline_id            => nil,
      :molecular_structure_id => nil
    }
    assert_response :unprocessable_entity
  end
  
  should "destroy targeting_vector" do
    assert_difference('TargetingVector.count', -1) do
      delete :destroy, :id => TargetingVector.find(:first).to_param
    end
    assert_response :success
  end
end
