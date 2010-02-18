class AddMutationDetailsToMolecularStructure < ActiveRecord::Migration
  def self.up
    add_column :molecular_structures, :mutation_type, :string
    add_column :molecular_structures, :mutation_subtype, :string
    add_column :molecular_structures, :mutation_method, :string
    add_column :molecular_structures, :reporter, :string
  end

  def self.down
    remove_column :molecular_structures, :reporter
    remove_column :molecular_structures, :mutation_method
    remove_column :molecular_structures, :mutation_subtype
    remove_column :molecular_structures, :mutation_type
  end
end
