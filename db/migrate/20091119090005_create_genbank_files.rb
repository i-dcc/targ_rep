class CreateGenbankFiles < ActiveRecord::Migration
  def self.up
    create_table :genbank_files do |t|
      t.integer     :molecular_structure_id,  :null => false
      
      t.text        :escell_clone
      t.text        :targeting_vector
      t.timestamps
    end
    
    add_foreign_key( :genbank_files, :molecular_structures, :dependent => :delete, :name => 'genbank_files_molecular_structure_id_fk' )
  end
  
  def self.down
    drop_table :genbank_files
  end
end
