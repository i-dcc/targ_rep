class CreateMolecularStructures < ActiveRecord::Migration
  def self.up
    create_table :molecular_structures do |t|
      t.string    :assembly,            :null => false, :default => "NCBIM37"
      t.string    :chromosome,          :null => false
      t.string    :strand,              :null => false
      t.string    :mgi_accession_id,    :null => false
      
      t.string    :allele_symbol_superscript
      t.integer   :homology_arm_start,  :null => false
      t.integer   :homology_arm_end,    :null => false
      t.integer   :loxp_start
      t.integer   :loxp_end
      t.integer   :cassette_start
      t.integer   :cassette_end
      t.string    :cassette
      t.string    :backbone
      
      t.string    :design_type,         :null => false
      t.string    :design_subtype
      t.string    :subtype_description
      
      t.integer   :created_by
      t.integer   :updated_by
      t.timestamps
    end

    add_index :molecular_structures,
      [
        :assembly, :chromosome, :strand,
        :homology_arm_start, :homology_arm_end,
        :cassette_start, :cassette_end,
        :loxp_start, :loxp_end,
        :cassette, :backbone,
        :allele_symbol_superscript
      ],
      :name => "index_mol_struct",
      :unique => true
  end
  
  def self.down
    drop_table :molecular_structures
  end
end
