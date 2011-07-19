class AddEsCellStrainToCell < ActiveRecord::Migration
  def self.up
    add_column :es_cells, :strain, :string, :limit => 25
  end

  def self.down
    remove_column :es_cells, :strain
  end
end
