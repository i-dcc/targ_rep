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

    mutation_methods = MutationMethod.create([
      { :id => 1, :name => 'Targeted mutation', :code => 'tgm' },
      { :id => 2, :name => 'Recombination mediated cassette exchange', :code=> 'rmce' }
    ])

    mutation_types = MutationType.create([
      { :id => 1, :name => 'Conditional Ready', :code => 'crd' },
      { :id => 2, :name => 'Deletion', :code => 'del' },
      { :id => 3, :name => 'Targeted non-conditional', :code => 'tnc' },
      { :id => 4, :name => 'Cre knock-in', :code => 'cki' },
      { :id => 5, :name => 'Cre BAC', :code => 'cbc'}
    ])

    mutation_sub_types = MutationSubtype.create([
      { :id => 1, :name => 'Domain disruption', :code => 'dmd' },
      { :id => 2, :name => 'Frameshift', :code => 'fms' },
      { :id => 3, :name => 'Artificial intron', :code => 'afi' },
      { :id => 4, :name => 'Hprt', :code => 'hpt'},
      { :id => 5, :name => 'Rosa26', :code => 'rsa' }
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

    Allele.reset_column_information
    MutationMethod.reset_column_information
    MutationType.reset_column_information
    MutationSubtype.reset_column_information
    Allele.all.each do |allele|
      if mapping.has_key?(allele.mut_type)
        allele.mutation_method = MutationMethod.find_by_name(mapping[allele.mut_type])
      end
      if mapping.has_key?(allele.mut_subtype)
        allele.mutation_type = MutationType.find_by_name(mapping[allele.mut_subtype])
      end
      if mapping.has_key?(allele.mut_method)
        allele.mutation_subtype = MutationSubtype.find_by_name(mapping[allele.mut_method])
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