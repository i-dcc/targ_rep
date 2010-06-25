require 'test_helper'

class EsCellTest < ActiveSupport::TestCase
  setup do
    Factory.create( :es_cell )
    # ES Cell has been validated and saved successfully
  end
  
  should belong_to(:created_by)
  should belong_to(:updated_by)
  should belong_to(:molecular_structure)
  should belong_to(:targeting_vector)
  
  should validate_uniqueness_of(:name).with_message('This ES Cell name has already been taken')
  should validate_presence_of(:name)
  should validate_presence_of(:molecular_structure_id)
  
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
        mol_struct  = Factory.create( :molecular_structure )
        
        es_cell = EsCell.new({
          :name                   => 'INVALID',
          :targeting_vector_id    => targ_vec.id,
          :molecular_structure_id => mol_struct.id
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
          :name                   => 'EPD001',
          :targeting_vector_id    => targ_vec.id,
          :molecular_structure_id => targ_vec.molecular_structure_id
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
          :name                   => "EPD001",
          :ikmc_project_id        => "DIFFERENT FROM TARG_VEC'S ONE",
          :targeting_vector_id    => targ_vec.id,
          :molecular_structure_id => targ_vec.molecular_structure_id,
        })
        
        assert( !es_cell.valid?, "ES Cell validates an invalid entry" )
        assert( !es_cell.save, "ES Cell validates the creation of an invalid entry" )
      end
    end
  end
end
