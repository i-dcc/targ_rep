class MoveMgiAlleleIdToEscells < ActiveRecord::Migration
  def self.up
    remove_column :alleles, :mgi_allele_id
    add_column :es_cells, :mgi_allele_id, :string, :limit => 50
  end

  def self.down
    remove_column :es_cells, :mgi_allele_id
    add_column :alleles, :mgi_allele_id, :string, :limit => 50
  end
end