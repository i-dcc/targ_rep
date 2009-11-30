class CreateGenbankFiles < ActiveRecord::Migration
  def self.up
    create_table :genbank_files do |t|
      t.foreign_key :molecular_structures,    :dependent => :delete
      t.integer     :molecular_structure_id,  :null => false
      
      t.text        :escell_clone
      t.text        :targeting_vector
      t.timestamps
    end
  end
  
  def self.down
    drop_table :genbank_files
  end
end
