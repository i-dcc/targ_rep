class CreateMutationTables < ActiveRecord::Migration

  def self.up
    add_column :alleles, :mutation_method_id, :integer
    add_column :alleles,  :mutation_type_id, :integer
    add_column :alleles,  :mutation_sub_type_id, :integer

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

    remove_column :alleles, :mutation_method_id, :integer
    remove_column :alleles,  :mutation_type_id, :integer
    remove_column :alleles,  :mutation_sub_type_id, :integer

    drop_table :mutation_methods
    drop_table :mutation_types
    drop_table :mutation_sub_types
  end
end