require 'test_helper'

class EsCellTest < ActiveSupport::TestCase
  setup do
    Factory.create( :es_cell )
    # ES Cell has been validated and saved successfully
  end
  
  should belong_to(:allele)
  should belong_to(:targeting_vector)
  
  should validate_uniqueness_of(:name).with_message('This ES Cell name has already been taken')
  should validate_presence_of(:name)
  should validate_presence_of(:allele_id)
  
  pass_fail_only_qc_fields = [
    :production_qc_three_prime_screen,
    :production_qc_loxp_screen,
    :production_qc_loss_of_allele,
    :production_qc_vector_integrity,
    :distribution_qc_copy_number,
    :distribution_qc_five_prime_sr_pcr,
    :distribution_qc_three_prime_sr_pcr,
    :user_qc_five_prime_lr_pcr,
    :user_qc_three_prime_lr_pcr,
    :user_qc_map_test,
    :user_qc_tv_backbone_assay,
    :user_qc_loxp_confirmation,
    :user_qc_loss_of_wt_allele,
    :user_qc_neo_count_qpcr,
    :user_qc_lacz_sr_pcr,
    :user_qc_mutant_specific_sr_pcr,
    :user_qc_five_prime_cassette_integrity,
    :user_qc_neo_sr_pcr
  ]
  
  pass_fail_only_qc_fields.each do |qc_field|
    should allow_value('pass').for(qc_field)
    should allow_value('fail').for(qc_field)
    should_not allow_value('wibble').for(qc_field)
  end
  
  should validate_numericality_of(:distribution_qc_karyotype_low)
  should validate_numericality_of(:distribution_qc_karyotype_high)
  
  should ensure_inclusion_of(:distribution_qc_karyotype_low).in_range(0..1).with_message(/must be less than or equal/)
  should ensure_inclusion_of(:distribution_qc_karyotype_high).in_range(0..1).with_message(/must be less than or equal/)
  
  context "ES Cell" do
    context "with empty attributes" do
      should "not be saved" do
        es_cell = Factory.build( :invalid_escell )
        
        assert( !es_cell.valid?, "ES Cell validates an empty entry" )
        assert( !es_cell.save, "ES Cell validates the creation of an empty entry" )
      end
    end
    
    context "with molecular structure consistency issue" do
      should "not be saved" do
        targ_vec    = Factory.create( :targeting_vector )
        mol_struct  = Factory.create( :allele )
        
        es_cell = EsCell.new({
          :name                => 'INVALID',
          :targeting_vector_id => targ_vec.id,
          :allele_id           => mol_struct.id
        })
        
        assert( !es_cell.valid?, "ES Cell validates an invalid entry" )
        assert( !es_cell.save, "ES Cell validates the creation of an invalid entry" )
      end
    end
    
    context "with an IKMC Project ID copied from its targeting vector's" do
      should "be saved" do
        targ_vec = Factory.create( :targeting_vector )
        
        # ikmc_project_id is not provided
        es_cell = EsCell.new({
          :name                => 'EPD001',
          :targeting_vector_id => targ_vec.id,
          :allele_id           => targ_vec.allele_id
        })
        
        assert( es_cell.valid?, "ES Cell does not validate a valid entry" )
        assert( es_cell.save, "ES Cell does not validate the creation of a valid entry" )
        assert( es_cell.ikmc_project_id == targ_vec.ikmc_project_id, "ES Cell should have copied the ikmc_project_id from its targeting vector's" )
      end
    end
    
    context "with IKMC Project ID consistency issue" do
      should "not be saved" do
        targ_vec = Factory.create( :targeting_vector )
        
        es_cell = EsCell.new({
          :name                => "EPD001",
          :ikmc_project_id     => "DIFFERENT FROM TARG_VEC'S ONE",
          :targeting_vector_id => targ_vec.id,
          :allele_id           => targ_vec.allele_id,
        })
        
        assert( !es_cell.valid?, "ES Cell validates an invalid entry" )
        assert( !es_cell.save, "ES Cell validates the creation of an invalid entry" )
      end
    end
  end
end
