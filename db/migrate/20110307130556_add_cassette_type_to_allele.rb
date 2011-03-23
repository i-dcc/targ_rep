class AddCassetteTypeToAllele < ActiveRecord::Migration
  def self.up
    add_column :alleles, :cassette_type, :string
  end

  def self.down
    remove_column :alleles, :cassette_type
  end
end