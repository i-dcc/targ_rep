class CreateQcFieldDescriptions < ActiveRecord::Migration
  def self.up
    create_table :qc_field_descriptions do |t|
      t.string :qc_field, :null => false
      t.text :description, :null => false
      t.string :url
      t.timestamps
    end
    
    add_index :qc_field_descriptions, [:qc_field], :unique => true
  end

  def self.down
    remove_index :qc_field_descriptions, :column => [:qc_field]
    drop_table :qc_field_descriptions
  end
end
