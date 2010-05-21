class AddIkmcProjectIdToEsCell < ActiveRecord::Migration
  def self.up
    add_column :es_cells, :ikmc_project_id, :string
  end
  
  def self.down
    remove_column :es_cells, :ikmc_project_id
  end
end
