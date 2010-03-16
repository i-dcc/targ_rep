class MovePipelineToMolecularStructure < ActiveRecord::Migration
  def self.up
    add_column :molecular_structures, :pipeline_id, :integer
    add_foreign_key( :molecular_structures, :pipelines, :dependent => :delete, :name => 'molecular_structures_pipeline_id_fk' )
    
    TargetingVector.all.each do |targ_vec|
      mol_struct = targ_vec.molecular_structure
      mol_struct.pipeline_id = targ_vec.pipeline_id
      mol_struct.save
    end
    
    remove_foreign_key( :targeting_vectors, :pipelines )
    remove_column :targeting_vectors, :pipeline_id
  end

  def self.down
    add_column :targeting_vectors, :pipeline_id, :integer
    add_foreign_key :targeting_vectors, :pipelines, :dependent => :delete
    
    TargetingVector.all.each do |targ_vec|
      mol_struct = targ_vec.molecular_structure
      targ_vec.pipeline_id = mol_struct.pipeline_id
      targ_vec.save
    end
    
    remove_foreign_key( :molecular_structures, :pipelines )
    remove_column :molecular_structures, :pipeline_id
  end
end
