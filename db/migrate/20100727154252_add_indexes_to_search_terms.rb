class AddIndexesToSearchTerms < ActiveRecord::Migration
  def self.up
    add_index :es_cells, [:name], :unique => true
    add_index :molecular_structures, :mgi_accession_id
    add_index :pipelines, :name
  end

  def self.down
    remove_index :pipelines, :name
    remove_index :es_cells, :column => [:name]
    remove_index :molecular_structures, :mgi_accession_id
  end
end