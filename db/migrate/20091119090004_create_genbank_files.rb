class CreateGenbankFiles < ActiveRecord::Migration
  def self.up
    create_table :genbank_files do |t|
      t.text :escell_clone
      t.text :targeting_vector
      t.timestamps
    end
  end
  
  def self.down
    drop_table :genbank_files
  end
end
