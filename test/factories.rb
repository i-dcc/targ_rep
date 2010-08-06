##
##  Factory helpers
##
Factory.sequence(:pgdgr_plate_name) { |n| "PGDGR_#{n}" }
Factory.sequence(:epd_plate_name) { |n| "EPD_#{n}" }
Factory.sequence(:pipeline_name) { |n| "pipeline_name_#{n}" }
Factory.sequence(:ikmc_project_id) { |n| "project_000#{n}" }

##
## Users
##

Factory.define :user do |u|
  u.sequence(:username)            { |n| "bob#{n}" }
  u.sequence(:email)               { |n| "bob#{n}@bobsworld.com" }
  u.password                       "secret"
  u.password_confirmation          { |u| u.password }
  u.sequence(:persistence_token)   { |n| "token_#{n}" }
  u.is_admin                       false
end

Factory.define :invalid_user, :class => User do |u|
end

##
## Pipelines
##

Factory.define :pipeline do |f|
  f.name { Factory.next(:pipeline_name) }
end

Factory.define :invalid_pipeline, :class => Pipeline do |f|
end

##
## Molecular Structure
##

Factory.define :allele do |f|
  f.sequence(:mgi_accession_id)           { |n| "MGI:#{n}" }
  f.sequence(:project_design_id)          { |n| "design id #{n}"}
  f.sequence(:design_subtype)             { |n| "subtype #{n}" }
  f.sequence(:subtype_description)        { |n| "subtype description #{n}" }
  f.sequence(:cassette)                   { |n| "cassette #{n}"}
  f.sequence(:backbone)                   { |n| "backbone #{n}"}
  
  f.association :pipeline
  
  f.assembly    "NCBIM37"
  f.chromosome  { [("1".."19").to_a + ['X', 'Y', 'MT']].flatten[rand(22)] }
  f.strand      { ['+', '-'][rand(2)] }
  f.design_type { ['Knock Out', 'Deletion', 'Insertion'][rand(3)] }
  
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
  f.homology_arm_start do |allele|
    case allele.strand
      when '+' then 10
      when '-' then 160
    end
  end
  
  f.homology_arm_end do |allele|
    case allele.strand
      when '+' then 160
      when '-' then 10
    end
  end
  
  # Cassette
  f.cassette_start do |allele|
    case allele.strand
      when '+' then 40
      when '-' then 130
    end
  end
  f.cassette_end do |allele|
    case allele.strand
      when '+' then 70
      when '-' then 100
    end
  end
  
  # LoxP
  f.loxp_start do |allele|
    if allele.design_type == 'Knock Out'
      case allele.strand
        when '+' then 100
        when '-' then 70
      end
    end
  end
  
  f.loxp_end do |allele|
    if allele.design_type == 'Knock Out'
      case allele.strand
        when '+' then 130
        when '-' then 40
      end
    end
  end
end

Factory.define :invalid_allele, :class => Allele do |f|
end

##
## Targeting Vector
##

Factory.define :targeting_vector do |f|
  f.name { Factory.next(:pgdgr_plate_name) }
  f.ikmc_project_id { Factory.next(:ikmc_project_id) }
  f.association :allele
end

Factory.define :invalid_targeting_vector, :class => TargetingVector do |f|
end

##
## ES Cells
##

Factory.define :es_cell do |f|
  f.name                { Factory.next(:epd_plate_name) }
  f.parental_cell_line  { ['JM8 parental', 'JM8.F6', 'JM8.N19'][rand(3)] }
  
  ikmc_project_id = Factory.next( :ikmc_project_id )
  
  f.association :allele
  f.targeting_vector { |es_cell|
    es_cell.association( :targeting_vector, { 
      :allele_id       => es_cell.allele_id,
      :ikmc_project_id => ikmc_project_id
    })
  }
  f.ikmc_project_id { ikmc_project_id }
end

Factory.define :invalid_escell, :class => EsCell do |f|
end

##
## GenBank files
##

Factory.define :genbank_file do |f|
  f.sequence(:escell_clone)       { |n| "ES Cell clone file #{n}" }
  f.sequence(:targeting_vector)   { |n| "Targeting vector file #{n}" }
  
  f.association :allele
end

Factory.define :invalid_genbank_file, :class => GenbankFile do |f|
end

##
## QcFieldDescription
##

Factory.define :qc_field_description do |f|
  f.sequence(:qc_field) { |n| "qc_#{n}_foobar" }
  f.description "w00t wibble blibble blip"
end