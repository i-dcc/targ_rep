class PopulateDataAndRemoveColumns < ActiveRecord::Migration

  class Allele < ActiveRecord::Base
    belongs_to :mutation_method
    belongs_to :mutation_type
    belongs_to :mutation_subtype
    has_one    :genbank_file,      :class_name => "GenbankFile",     :foreign_key => "allele_id"
    has_many   :targeting_vectors, :class_name => "TargetingVector", :foreign_key => "allele_id"
    has_many   :es_cells,          :class_name => "EsCell",          :foreign_key => "allele_id"
  end

  class MutationMethod < ActiveRecord::Base
    has_many :allele, :class_name => "Allele", :foreign_key => "mutation_method_id"
  end

  class MutationType < ActiveRecord::Base
    has_many :allele, :class_name => "Allele", :foreign_key => "mutation_type_id"
  end

  class MutationSubtype < ActiveRecord::Base
    has_many :allele, :class_name => "Allele", :foreign_key => "mutation_subtype_id"
  end

  def self.up

    mutation_methods = MutationMethod.create([
      { :id => 1, :name => 'Targeted Mutation', :code => 'tgm' },
      { :id => 2, :name => 'Recombination Mediated Cassette Exchange', :code=> 'rmce' }
    ])

    mutation_types = MutationType.create([
      { :id => 1, :name => 'Conditional Ready', :code => 'crd' },
      { :id => 2, :name => 'Deletion', :code => 'del' },
      { :id => 3, :name => 'Targeted Non Conditional', :code => 'tnc' },
      { :id => 4, :name => 'Cre Knock In', :code => 'cki' },
      { :id => 5, :name => 'Cre BAC', :code => 'cbc'}
    ])

    mutation_sub_types = MutationSubtype.create([
      { :id => 1, :name => 'Domain Disruption', :code => 'dmd' },
      { :id => 2, :name => 'Frameshift', :code => 'fms' },
      { :id => 3, :name => 'Artificial Intron', :code => 'afi' },
      { :id => 4, :name => 'Hprt', :code => 'hpt'},
      { :id => 5, :name => 'Rosa26', :code => 'rsa' }
    ])

    mapping = {
      'frameshift' => 'Frameshift',
      'domain_disruption' => 'Domain Disruption',
      'targeted_mutation' => 'Targeted Mutation',
      'conditional_ready' => 'Conditional Ready',
      'deletion' => 'Deletion',
      'targeted_non_conditional' => 'Targeted Non Conditional',
      'insertion' => 'Cre knock In'
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
    remove_column :alleles, :mut_method
    remove_column :alleles, :mut_type
    remove_column :alleles, :mut_subtype
    remove_column :alleles, :design_type
    remove_column :alleles, :design_subtype
  end

  def self.down

    create_column :alleles, :mut_method, :string
    create_column :alleles, :mut_type, :string
    create_column :alleles, :mut_subtype, :string
    create_column :alleles, :design_type, :string
    create_column :alleles, :design_subtype, :string
  end
end