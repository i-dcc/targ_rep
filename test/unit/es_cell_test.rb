require 'test_helper'

class EsCellTest < ActiveSupport::TestCase
  setup do
    Factory.create( :es_cell )
    # ES Cell has been validated and saved successfully
  end
  
  should belong_to(:pipeline)
  should belong_to(:allele)
  should belong_to(:targeting_vector)
  
  should validate_uniqueness_of(:name).with_message('This ES Cell name has already been taken')
  should validate_presence_of(:name)
  should validate_presence_of(:allele_id)
  
  pass_fail_only_qc_fields = [
    :production_qc_loss_of_allele,
    :production_qc_vector_integrity,
    :distribution_qc_copy_number,
    :distribution_qc_five_prime_lr_pcr,
    :distribution_qc_three_prime_lr_pcr,
    :distribution_qc_five_prime_sr_pcr,
    :distribution_qc_three_prime_sr_pcr,
    :distribution_qc_thawing,
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
  
  pass_not_confirmed_qc_fields = [
    :production_qc_five_prime_screen,
    :production_qc_three_prime_screen,
    :production_qc_loxp_screen
  ]
  
  pass_not_confirmed_qc_fields.each do |qc_field|
    should allow_value('pass').for(qc_field)
    should allow_value('not confirmed').for(qc_field)
    should_not allow_value('fail').for(qc_field)
    should_not allow_value('wibble').for(qc_field)
  end
  
  should validate_numericality_of(:distribution_qc_karyotype_low)
  should validate_numericality_of(:distribution_qc_karyotype_high)
  
  should ensure_inclusion_of(:distribution_qc_karyotype_low).in_range(0..1).with_message(/must be less than or equal/)
  should ensure_inclusion_of(:distribution_qc_karyotype_high).in_range(0..1).with_message(/must be less than or equal/)
  
  context "An ES Cell" do
    should "not be saved if it has empty attributes" do
      es_cell = Factory.build( :invalid_escell )
      
      assert( !es_cell.valid?, "ES Cell validates an empty entry" )
      assert( !es_cell.save, "ES Cell validates the creation of an empty entry" )
    end
    
    should "not be saved if it has an incorrect MGI Allele ID" do
      es_cell = Factory.build( :es_cell, :mgi_allele_id => 'WIBBLE' )
      assert( !es_cell.save, "An ES Cell is saved with an incorrect MGI Allele ID" )
    end
    
    should "not be saved if it has molecular structure consistency issue" do
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
    
    should "copy the IKMC project id from it's TV if the project id is empty" do
      targ_vec = Factory.create( :targeting_vector )
      
      # ikmc_project_id is not provided
      es_cell = EsCell.new({
        :name                => 'EPD001',
        :targeting_vector_id => targ_vec.id,
        :allele_id           => targ_vec.allele_id,
        :pipeline_id         => targ_vec.pipeline_id
      })
      
      assert( es_cell.valid?, "ES Cell does not validate a valid entry" )
      assert( es_cell.save, "ES Cell does not validate the creation of a valid entry" )
      assert( es_cell.ikmc_project_id == targ_vec.ikmc_project_id, "ES Cell should have copied the ikmc_project_id from its targeting vector's" )
    end
    
    should "cope gracefully if a user tries to send in an integer as an IKMC Project ID" do
      targ_vec = Factory.create( :targeting_vector )
      targ_vec.ikmc_project_id = "12345678"
      targ_vec.save
      
      es_cell = EsCell.new({
        :name                => "EPD12345678",
        :ikmc_project_id     => 12345678,
        :targeting_vector_id => targ_vec.id,
        :allele_id           => targ_vec.allele_id,
        :pipeline_id         => targ_vec.pipeline_id
      })
      
      assert( es_cell.valid?, "ES Cell does not validate a valid entry" )
      assert( es_cell.save, "ES Cell does not validate the creation of a valid entry" )
    end

    should "set mirKO ikmc_project_ids to 'mirKO' + self.allele_id" do
      pipeline = Factory.create( :pipeline, :name => "mirKO" )
      allele   = Factory.create( :allele )
      targ_vec = Factory.create( :targeting_vector, :pipeline => pipeline, :allele => allele, :ikmc_project_id => nil )
      es_cell  = Factory.create( :es_cell, :pipeline => pipeline, :allele => allele, :targeting_vector => targ_vec, :ikmc_project_id => nil )
      assert_equal( "mirKO#{ allele.id }", es_cell.ikmc_project_id )
      assert_equal( targ_vec.ikmc_project_id, es_cell.ikmc_project_id )
    end

    should "set the ES cell strain correctly" do
      good_tests = {
        'JM8N4'     => 'C57BL/6N',
        'JM8wibble' => 'C57BL/6N',
        'C2'        => 'C57BL/6N',
        'C2.2'      => 'C57BL/6N',
        'AB2.2'     => '129S7',
        'AB2.2a'    => '129S7'
      }

      good_tests.each do |cell_line,expected_strain|
        es_cell = Factory.create( :es_cell, :parental_cell_line => cell_line )
        assert_equal( expected_strain, es_cell.strain )
      end

      ['JM4','wibble'].each do |cell_line|
        es_cell = Factory.build( :es_cell, :parental_cell_line => cell_line )
        assert_false es_cell.valid?
        assert_false es_cell.save
      end
    end
  end
end

