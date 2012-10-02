class CreateMutationTables < ActiveRecord::Migration

  def self.up
    create_table :mutation_methods do |t|
      t.string :name, :null => false, :limit => 100
      t.timestamps
    end

    create_table :mutation_types do |t|
      t.string :name, :null => false, :limit => 100
      t.timestamps
    end

    create_table :mutation_sub_types do |t|
      t.string :name, :null => false, :limit => 100
      t.timestamps
    end
  end

  def self.down
    drop_table :mutation_methods
    drop_table :mutation_types
    drop_table :mutation_sub_types
  end
end