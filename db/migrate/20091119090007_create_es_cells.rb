class CreateEsCells < ActiveRecord::Migration
  def self.up
    create_table :es_cells do |t|
      t.integer       :molecular_structure_id,  :null => false
      t.integer       :targeting_vector_id
      t.string        :parental_cell_line
      t.string        :allele_symbol_superscript
      t.string        :name,                    :null => false
      
      t.integer       :created_by
      t.integer       :updated_by
      t.timestamps
    end
    
    add_foreign_key( :es_cells, :molecular_structures, :dependent => :delete, :name => 'es_cells_molecular_structure_id_fk' )
    add_foreign_key( :es_cells, :targeting_vectors,    :dependent => :delete, :name => 'es_cells_targeting_vector_id_fk' )
  end
  
  def self.down
    drop_table :es_cells
  end
end
