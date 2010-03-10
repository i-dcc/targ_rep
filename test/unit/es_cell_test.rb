require 'test_helper'

class EsCellTest < ActiveSupport::TestCase
  setup do
    Factory.create( :es_cell )
    # ES Cell has been validated and saved successfully
  end
  
  should_belong_to :created_by, :updated_by
  should_belong_to :molecular_structure, :targeting_vector
  
  should_validate_uniqueness_of :name
  should_validate_presence_of :name
  should_validate_presence_of :molecular_structure_id
  
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
  end
end
