class PopulateDataAndRemoveColumns < ActiveRecord::Migration

  def self.up

    mapping = {
      'frameshift' => "(SELECT id FROM mutation_subtypes WHERE name = 'Frameshift')",
      'domain_disruption' => "(SELECT id FROM mutation_subtypes WHERE name = 'Domain Disruption')",
      'targeted_mutation' => "(SELECT id FROM mutation_methods WHERE name = 'Targeted Mutation')",
      'conditional_ready' => "(SELECT id FROM mutation_types WHERE name= 'Conditional Ready')",
      'deletion' => "(SELECT id FROM mutation_types WHERE name= 'Deletion')",
      'targeted_non_conditional' => "(SELECT id FROM mutation_types WHERE name= 'Targeted Non Conditional')",
      'insertion' => "(SELECT id FROM mutation_types WHERE name= 'Cre knock In')"
      }

    sql= <<-"EOL"
    CREATE TEMPORARY TABLE lookup (thing VARCHAR(100), thing_to INT);
    INSERT INTO lookup (thing, thing_to) VALUES ('frameshift', #{mapping['frameshift']});
    INSERT INTO lookup (thing, thing_to) VALUES ('domain_disruption', #{mapping['domain_disruption']});
    INSERT INTO lookup (thing, thing_to) VALUES ('targeted_mutation', #{mapping['targeted_mutation']});
    INSERT INTO lookup (thing, thing_to) VALUES ('conditional_ready', #{mapping['conditional_ready']});
    INSERT INTO lookup (thing, thing_to) VALUES ('deletion', #{mapping['deletion']});
    INSERT INTO lookup (thing, thing_to) VALUES ('targeted_non_conditional', #{mapping['targeted_non_conditional']});
    INSERT INTO lookup (thing, thing_to) VALUES ('insertion', #{mapping['insertion']});
    UPDATE alleles INNER JOIN lookup ON alleles.mut_type = lookup.thing SET mutation_method_id = lookup.thing_to;
    UPDATE alleles INNER JOIN lookup ON alleles.mut_subtype = lookup.thing SET mutation_type_id = lookup.thing_to;
    UPDATE alleles INNER JOIN lookup ON alleles.mut_method = lookup.thing SET mutation_subtype_id = lookup.thing_to;
    EOL

    sql.strip.split("\n").each {|s| execute s.strip}
    remove_column :alleles, :mut_method
    remove_column :alleles, :mut_type
    remove_column :alleles, :mut_subtype
    remove_column :alleles, :design_type
    remove_column :alleles, :design_subtype
  end

  def self.down

    add_column :alleles, :mut_method, :string
    add_column :alleles, :mut_type, :string
    add_column :alleles, :mut_subtype, :string
    add_column :alleles, :design_type, :string
    add_column :alleles, :design_subtype, :string
  end
end