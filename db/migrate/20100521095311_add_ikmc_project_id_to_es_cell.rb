class AddIkmcProjectIdToEsCell < ActiveRecord::Migration
  def self.up
    add_column :es_cells, :ikmc_project_id, :string
    
    # Copy IKMC Project ID from targeting vector to ES Cell
    execute "
      UPDATE es_cells
      SET ikmc_project_id = (
        SELECT ikmc_project_id
        FROM targeting_vectors
        WHERE targeting_vectors.id = es_cells.targeting_vector_id
      )
    "
  end
  
  def self.down
    remove_column :es_cells, :ikmc_project_id
  end
end
