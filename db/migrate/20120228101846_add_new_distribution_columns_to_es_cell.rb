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


#Add these fields to the ES cells model and REST interface
#
#Distribution centre:
#
#QC fields:
#distribution_loa << this could be found by 3' or 5' probe
#distribution_loxp << taqman -based check with probe in loxp
#distribution_lacz << taqman -based check with probe in lacz part of cassette
#distribution_chr1
#distribution_chr8a
#distribution_chr8b
#distribution_chr11a
#distribution_chr11b
#distribution_chry
#
#Each field has to store these values:
#
#pass, fail, null
