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
      t.timestamps
    end

    create_table :mutation_types do |t|
      t.string :name, :null => false, :limit => 100
      t.timestamps
    end

    create_table :mutation_subtypes do |t|
      t.string :name, :null => false, :limit => 100
      t.timestamps
    end

    mutation_methods = MutationMethod.create([
      { :id => 1, :name => 'Targeted mutation' },
      { :id => 2, :name => 'Recombination mediated cassette exchange' }
    ])

    mutation_types = MutationType.create([
      { :id => 1, :name => 'Conditional Ready' },
      { :id => 2, :name => 'Deletion' },
      { :id => 3, :name => 'Targeted non-conditional' },
      { :id => 4, :name => 'Cre knock-in' },
      { :id => 5, :name => 'Cre BAC' }
    ])

    mutation_sub_types = MutationSubtype.create([
      { :id => 1, :name => 'Domain disruption' },
      { :id => 2, :name => 'Frameshift' },
      { :id => 3, :name => 'Artificial intron' },
      { :id => 4, :name => 'Hprt' },
      { :id => 5, :name => 'Rosa26' }
    ])

    mapping = {
      'frameshift' => 'Frameshift',
      'domain_disruption' => 'Domain disruption',
      'targeted_mutation' => 'Targeted mutation',
      'conditional_ready' => 'Conditional Ready',
      'deletion' => 'Deletion',
      'targeted_non_conditional' => 'Targeted non-conditional',
      'insertion' => 'Cre knock-in'
      }

    Allele.all.each do |allele|
      if mapping.has_key?(mut_method)
        allele.mutation_method = Mutation.find_by_name(mapping(allele.mut_method))
      end
      if mapping.has_key?(mut_type)
        allele.mutation_type = Mutation.find_by_name(mapping(allele.mut_type))
      end
      if mapping.has_key?(mut_subtype)
        allele.mutation_subtype = Mutation.find_by_name(mapping(allele.mut_subtype))
      end
      allele.save!
    end
#    remove_column :alleles, :mut_method
#    remove_column :alleles, :mut_type
#    remove_column :alleles, :mut_subtype
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
#    create_column :alleles, :mutaion_method, :string
#    create_column :alleles, :mutaion_type, :string
#    create_column :alleles, :mutaion_subtype, :string
  end
end