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
    assert_difference('MolecularStructure.count') do
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
    end
  end
  
  should "not create targeting vector if molecular structure is wrong" do
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
  end

  should "show targeting_vector" do
    get :show, :id => TargetingVector.find(:first).to_param
    assert_response :success
  end

  should "update targeting_vector" do
    put :update, :id => TargetingVector.find(:first).to_param, :targeting_vector => Factory.attributes_for( :targeting_vector )
    assert_response :success
  end

  should "destroy targeting_vector" do
    assert_difference('TargetingVector.count', -1) do
      delete :destroy, :id => TargetingVector.find(:first).to_param
    end
    assert_response :success
  end
end
