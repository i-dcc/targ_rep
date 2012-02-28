class AddNewDistributionColumnsToEsCell < ActiveRecord::Migration
  def self.up
    add_column :es_cells, :distribution_loa, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_loxp, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_lacz, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_chr1, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_chr8a, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_chr8b, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_chr11a, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_chr11b, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_chry, :string, :limit => 4, :null => true
  end

  def self.down
    remove_column :es_cells, :distribution_loa
    remove_column :es_cells, :distribution_loxp
    remove_column :es_cells, :distribution_lacz
    remove_column :es_cells, :distribution_chr1
    remove_column :es_cells, :distribution_chr8a
    remove_column :es_cells, :distribution_chr8b
    remove_column :es_cells, :distribution_chr11a
    remove_column :es_cells, :distribution_chr11b
    remove_column :es_cells, :distribution_chry
  end
end
