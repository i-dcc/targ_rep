class AddMgiAlleleIdToAlleles < ActiveRecord::Migration
  def self.up
    add_column :alleles, :mgi_allele_id, :string, :limit => 50
  end

  def self.down
    remove_column :alleles, :mgi_allele_id
  end
end