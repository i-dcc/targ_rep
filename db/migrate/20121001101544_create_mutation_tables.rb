class CreateMutationTables < ActiveRecord::Migration

  def self.up

    rename_column :alleles, :mutation_method, :mut_method
    rename_column :alleles, :mutation_type, :mut_type
    rename_column :alleles, :mutation_subtype, :mut_subtype

    add_column :alleles, :mutation_method_id, :integer
    add_column :alleles,  :mutation_type_id, :integer
    add_column :alleles,  :mutation_subtype_id, :integer

    create_table :mutation_methods do |t|
      t.string :name, :null => false, :limit => 100
      t.string :code, :null => false, :limit => 100
      t.timestamps
    end

    create_table :mutation_types do |t|
      t.string :name, :null => false, :limit => 100
      t.string :code, :null => false, :limit => 100
      t.timestamps
    end

    create_table :mutation_subtypes do |t|
      t.string :name, :null => false, :limit => 100
      t.string :code, :null => false, :limit => 100
      t.timestamps
    end

  end

  def self.down

    remove_column :alleles, :mutation_method_id
    remove_column :alleles,  :mutation_type_id
    remove_column :alleles,  :mutation_subtype_id

    drop_table :mutation_methods
    drop_table :mutation_types
    drop_table :mutation_subtypes

    rename_column :alleles, :mut_method, :mutation_method
    rename_column :alleles, :mut_type, :mutation_type
    rename_column :alleles, :mut_subtype, :mutation_subtype
  end
end