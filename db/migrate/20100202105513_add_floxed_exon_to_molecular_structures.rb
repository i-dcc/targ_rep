class AddFloxedExonToMolecularStructures < ActiveRecord::Migration
  def self.up
    add_column :molecular_structures, :floxed_start_exon, :string
    add_column :molecular_structures, :floxed_end_exon, :string
    add_column :molecular_structures, :project_design_id, :integer
  end

  def self.down
    remove_column :molecular_structures, :project_design_id
    remove_column :molecular_structures, :floxed_end_exon
    remove_column :molecular_structures, :floxed_start_exon
  end
end
