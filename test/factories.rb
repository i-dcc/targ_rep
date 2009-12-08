##
## Users
##

Factory.define :user do |u|
 u.sequence(:username)     { |n| "bob#{n}" }
 u.sequence(:email)        { |n| "bob#{n}@bobsworld.com" }
 u.password                "secret"
 u.password_confirmation   { |u| u.password }
 u.is_admin                false
end

Factory.define :invalid_user, :class => User do |u|
end

##
## Pipelines
##

Factory.define :pipeline do |f|
  f.sequence(:name) { |n| "pipeline#{n}" }
end

Factory.define :invalid_pipeline, :class => Pipeline do |f|
end

##
## Molecular Structure
##

Factory.define :molecular_structure do |f|
  f.sequence(:mgi_accession_id)           { |n| "MGI:#{n}" }
  f.sequence(:allele_symbol_superscript)  { |n| "allele_symbol_#{n}" }
  f.sequence(:design_subtype)             { |n| "subtype #{n}" }
  f.sequence(:subtype_description)        { |n| "subtype description #{n}" }
  f.sequence(:cassette)                   { |n| "cassette #{n}"}
  f.sequence(:backbone)                   { |n| "backbone #{n}"}
  
  f.assembly    "NCBIM37"
  f.chromosome  { [("1".."19").to_a + ['X', 'Y', 'MT']].flatten.choice }
  f.strand      { ['+', '-'].choice }
  f.design_type { ['Knock Out', 'Deletion'].choice }
  
  #     Features positions chose for this factory:
  #     They have been fixed so that complex tests can be cleaner. Otherwise,
  #     fot testing a single feature, each other feature position has to be 
  #     reset.
  #
  #     +--------------------+------------+------------+
  #     | Feature            | Strand '+' | Strand '-' |
  #     +--------------------+------------+------------+
  #     | Homology arm start | 10         | 160        |
  #     | Cassette start     | 40         | 130        |
  #     | Cassette end       | 70         | 100        |
  #     | LoxP start         | 100        | 70         | <- Absent for design
  #     | LoxP end           | 130        | 40         | <- type 'Knock Out'
  #     | Homology arm end   | 160        | 10         |
  #     +--------------------+------------+------------+
  #
  
  # Homology arm
  f.homology_arm_start do |mol_struc|
    case mol_struc.strand
      when '+' then 10
      when '-' then 160
    end
  end
  
  f.homology_arm_end do |mol_struc|
    case mol_struc.strand
      when '+' then 160
      when '-' then 10
    end
  end
  
  # Cassette
  f.cassette_start do |mol_struc|
    case mol_struc.strand
      when '+' then 40
      when '-' then 130
    end
  end
  f.cassette_end do |mol_struc|
    case mol_struc.strand
      when '+' then 70
      when '-' then 100
    end
  end
  
  # LoxP
  f.loxp_start do |mol_struc|
    if mol_struc.design_type == 'Knock Out'
      case mol_struc.strand
        when '+' then 100
        when '-' then 70
      end
    end
  end
  
  f.loxp_end do |mol_struc|
    if mol_struc.design_type == 'Knock Out'
      case mol_struc.strand
        when '+' then 130
        when '-' then 40
      end
    end
  end
end

Factory.define :invalid_molecular_structure, :class => MolecularStructure do |f|
end

##
## Targeting Vector
##

Factory.define :targeting_vector do |f|
  f.sequence(:name)                 { |n| "PRPGS#{n}"}
  f.sequence(:intermediate_vector)  { |n| "PCS#{n}" }
  f.sequence(:ikmc_project_id)      { |n| "#{n}" }
  f.parental_cell_line { ['JM8 parental', 'JM8.F6', 'JM8.N19'].choice }
  
  f.association :pipeline
  f.association :molecular_structure
end

Factory.define :invalid_targeting_vector, :class => TargetingVector do |f|
end

##
## ES Cells
##

Factory.define :es_cell do |f|
  f.sequence(:name) { |n| "EPD#{n}" }
  
  f.association :targeting_vector
  f.association :molecular_structure
end

Factory.define :invalid_escell, :class => EsCell do |f|
end

##
## GenBank files
##

Factory.define :genbank_file do |f|
  f.sequence(:escell_clone)       { |n| "ES Cell clone file #{n}" }
  f.sequence(:targeting_vector)   { |n| "Targeting vector file #{n}" }
  
  f.association :molecular_structure
end

Factory.define :invalid_genbank_file, :class => GenbankFile do |f|
end