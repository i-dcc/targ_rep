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
  should_validate_presence_of :targeting_vector_id
  
  context "ES Cell" do
    context "with empty attributes" do
      escell = Factory.build( :invalid_escell )
      should "not be saved" do
        assert( !escell.valid?, "ES Cell validates an empty entry" )
        assert( !escell.save, "ES Cell validates the creation of an empty entry" )
      end
    end
  end
end
