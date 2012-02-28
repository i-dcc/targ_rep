class AddNewDistributionColumnsToEsCell < ActiveRecord::Migration
  def self.up
    add_column :es_cells, :distribution_qc_loa, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_qc_loxp, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_qc_lacz, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_qc_chr1, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_qc_chr8a, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_qc_chr8b, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_qc_chr11a, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_qc_chr11b, :string, :limit => 4, :null => true
    add_column :es_cells, :distribution_qc_chry, :string, :limit => 4, :null => true
  end

  def self.down
    remove_column :es_cells, :distribution_qc_loa
    remove_column :es_cells, :distribution_qc_loxp
    remove_column :es_cells, :distribution_qc_lacz
    remove_column :es_cells, :distribution_qc_chr1
    remove_column :es_cells, :distribution_qc_chr8a
    remove_column :es_cells, :distribution_qc_chr8b
    remove_column :es_cells, :distribution_qc_chr11a
    remove_column :es_cells, :distribution_qc_chr11b
    remove_column :es_cells, :distribution_qc_chry
  end
end
