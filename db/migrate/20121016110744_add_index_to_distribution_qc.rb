class AddIndexToDistributionQc < ActiveRecord::Migration
  def self.up
#    execute "ALTER TABLE distribution_qcs ADD UNIQUE (centre_id, es_cell_id)"
    add_index "distribution_qcs", ["centre_id", "es_cell_id"], :name => "index_distribution_qcs_centre_es_cell", :unique => true
  end

  def self.down
    remove_index :distribution_qcs, ["centre_id", "es_cell_id"]
  end
end
