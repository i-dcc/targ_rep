class ChangeMolecularStructureIndex < ActiveRecord::Migration
  def self.up
    remove_index :molecular_structures, :name => "index_mol_struct"
    
    add_index :molecular_structures,
      [
        :mgi_accession_id, :project_design_id,
        :assembly, :chromosome, :strand,
        :homology_arm_start, :homology_arm_end,
        :cassette_start, :cassette_end,
        :loxp_start, :loxp_end,
        :cassette, :backbone
      ],
      :name => "index_mol_struct",
      :unique => true
  end
  
  def self.down
    remove_index :molecular_structures, :name => "index_mol_struct"
    
    add_index :molecular_structures,
      [
        :assembly, :chromosome, :strand,
        :homology_arm_start, :homology_arm_end,
        :cassette_start, :cassette_end,
        :loxp_start, :loxp_end,
        :cassette, :backbone
      ],
      :name => "index_mol_struct",
      :unique => true
  end
end
