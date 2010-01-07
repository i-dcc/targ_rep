class CreateTargetingVectors < ActiveRecord::Migration
  def self.up
    create_table :targeting_vectors do |t|
      t.foreign_key :pipelines,               :dependent => :delete
      t.integer     :pipeline_id,             :null => false
      
      t.foreign_key :molecular_structures,    :dependent => :delete
      t.integer     :molecular_structure_id,  :null => false
      
      t.string      :ikmc_project_id,         :null => false      
      t.string      :name,                    :null => false
      t.string      :intermediate_vector
      
      t.integer     :created_by
      t.integer     :updated_by
      t.timestamps
    end
    
    add_index :targeting_vectors,
      [:pipeline_id, :name],
      :name => "index_targvec",
      :unique => true
  end

  def self.down
    drop_table :targeting_vectors
  end
end
