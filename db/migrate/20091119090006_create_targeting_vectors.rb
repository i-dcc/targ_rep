class CreateTargetingVectors < ActiveRecord::Migration
  def self.up
    create_table :targeting_vectors do |t|
      t.integer     :pipeline_id,             :null => false
      t.integer     :molecular_structure_id,  :null => false
      
      t.string      :ikmc_project_id
      t.string      :name,                    :null => false
      t.string      :intermediate_vector
      
      t.integer     :created_by
      t.integer     :updated_by
      t.timestamps
    end
    
    add_foreign_key( :targeting_vectors, :molecular_structures, :dependent => :delete, :name => 'targeting_vectors_molecular_structure_id_fk')
    add_foreign_key( :targeting_vectors, :pipelines,            :dependent => :delete, :name => 'targeting_vectors_pipeline_id_fk')
      
    add_index :targeting_vectors,
      [:pipeline_id, :name],
      :name => "index_targvec",
      :unique => true
  end

  def self.down
    drop_table :targeting_vectors
  end
end
