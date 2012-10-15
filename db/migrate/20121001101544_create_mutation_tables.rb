class CreateMutationTables < ActiveRecord::Migration

  def self.up

    rename_column :alleles, :mutation_method, :mut_method
    rename_column :alleles, :mutation_type, :mut_type
    rename_column :alleles, :mutation_subtype, :mut_subtype

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

    add_column :alleles, :mutation_method_id, :integer
    add_column :alleles,  :mutation_type_id, :integer
    add_column :alleles,  :mutation_subtype_id, :integer

    sql= <<-"EOL"
    INSERT INTO mutation_methods (id, name, code) VALUES(1,'Targeted Mutation', 'tgm');
    INSERT INTO mutation_methods (id, name, code) VALUES(2,'Recombination Mediated Cassette Exchange', 'rmce');
    INSERT INTO mutation_types (id, name, code) VALUES(1,'Conditional Ready', 'crd');
    INSERT INTO mutation_types (id, name, code) VALUES(2,'Deletion', 'del');
    INSERT INTO mutation_types (id, name, code) VALUES(3,'Targeted Non Conditional', 'tnc');
    INSERT INTO mutation_types (id, name, code) VALUES(4,'Cre Knock In', 'cki');
    INSERT INTO mutation_types (id, name, code) VALUES(5,'Cre BAC', 'cbc');
    INSERT INTO mutation_subtypes (id, name, code) VALUES(1,'Domain Disruption', 'dmd');
    INSERT INTO mutation_subtypes (id, name, code) VALUES(2,'Frameshift', 'fms');
    INSERT INTO mutation_subtypes (id, name, code) VALUES(3,'Artificial Intron', 'afi');
    INSERT INTO mutation_subtypes (id, name, code) VALUES(4,'Hprt', 'hpt');
    INSERT INTO mutation_subtypes (id, name, code) VALUES(5,'Rosa26', 'rsa');
    EOL

    sql.strip.split("\n").each {|s| execute s.strip}

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