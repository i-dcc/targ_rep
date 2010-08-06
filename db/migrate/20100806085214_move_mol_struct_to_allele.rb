class MoveMolStructToAllele < ActiveRecord::Migration
  def self.up
    remove_foreign_key( :genbank_files,     :name => 'genbank_files_molecular_structure_id_fk' )
    remove_foreign_key( :targeting_vectors, :name => 'targeting_vectors_molecular_structure_id_fk' )
    remove_foreign_key( :es_cells,          :name => 'es_cells_molecular_structure_id_fk' )
    
    rename_table :molecular_structures, :alleles
    
    rename_column :genbank_files, :molecular_structure_id, :allele_id
    rename_column :targeting_vectors, :molecular_structure_id, :allele_id
    rename_column :es_cells, :molecular_structure_id, :allele_id
    
    add_foreign_key( :genbank_files, :alleles, :dependent => :delete, :name => 'genbank_files_allele_id_fk' )
    add_foreign_key( :targeting_vectors, :alleles, :dependent => :delete, :name => 'targeting_vectors_allele_id_fk')
    add_foreign_key( :es_cells, :alleles, :dependent => :delete, :name => 'es_cells_allele_id_fk' )
    
    execute "update audits set auditable_type = 'Allele' where auditable_type = 'MolecularStructure'"
  end

  def self.down
    execute "update audits set auditable_type = 'MolecularStructure' where auditable_type = 'Allele'"
    
    remove_foreign_key( :genbank_files,     :name => 'genbank_files_allele_id_fk' )
    remove_foreign_key( :targeting_vectors, :name => 'targeting_vectors_allele_id_fk' )
    remove_foreign_key( :es_cells,          :name => 'es_cells_allele_id_fk' )
    
    rename_column :es_cells, :allele_id, :molecular_structure_id
    rename_column :targeting_vectors, :allele_id, :molecular_structure_id
    rename_column :genbank_files, :allele_id, :molecular_structure_id
    
    rename_table :alleles, :molecular_structures
    
    add_foreign_key( :genbank_files, :molecular_structures, :dependent => :delete, :name => 'genbank_files_molecular_structure_id_fk' )
    add_foreign_key( :targeting_vectors, :molecular_structures, :dependent => :delete, :name => 'targeting_vectors_molecular_structure_id_fk')
    add_foreign_key( :es_cells, :molecular_structures, :dependent => :delete, :name => 'es_cells_molecular_structure_id_fk' )
  end
end