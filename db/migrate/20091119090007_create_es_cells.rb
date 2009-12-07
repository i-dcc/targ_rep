class CreateEsCells < ActiveRecord::Migration
  def self.up
    create_table :es_cells do |t|
      t.foreign_key   :molecular_structure,     :dependent => :delete
      t.integer       :molecular_structure_id,  :null => false
      
      t.foreign_key   :targeting_vector,        :dependent => :delete
      t.integer       :targeting_vector_id
      
      t.string        :name
      
      t.integer       :created_by
      t.integer       :updated_by
      t.timestamps
    end
  end
  
  def self.down
    drop_table :es_cells
  end
end
