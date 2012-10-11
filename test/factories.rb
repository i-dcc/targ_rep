##
##  Factory helpers
##
Factory.sequence(:pgdgr_plate_name) { |n| "PGDGR_#{n}" }
Factory.sequence(:epd_plate_name)   { |n| "EPD_#{n}" }
Factory.sequence(:pipeline_name)    { |n| "pipeline_name_#{n}" }
Factory.sequence(:ikmc_project_id)  { |n| "project_000#{n}" }
Factory.sequence(:mgi_allele_id)    { |n| "MGI:#{n}" }
Factory.sequence(:username)         { |n| "bob#{n}" }
Factory.sequence(:email)            { |n| "bob#{n}@bobsworld.com" }

# 4413674 starts the longest sequence VALID of sequential MGI accession IDs
Factory.sequence(:mgi_accession_id) { |n| "MGI:#{n + 4413674}" }

##
## User
##

Factory.define :user do |u|
  u.username                       { Factory.next(:username) }
  u.email                          { Factory.next(:email) }
  u.password_salt                  Authlogic::Random.hex_token
  u.password                       { |u| Authlogic::CryptoProviders::Sha512.encrypt( "secret" + u.password_salt ) }
  u.password_confirmation          { |u| u.password }
  u.sequence(:persistence_token)   { |n| "6cde06746_#{n}" }
  u.is_admin                       false
end

Factory.define :invalid_user, :class => User do |u|
end

##
## Pipeline
##

Factory.define :pipeline do |f|
  f.name { Factory.next(:pipeline_name) }
end

Factory.define :invalid_pipeline, :class => Pipeline do |f|
end

##
## Allele
##

Factory.define :allele do |f|
  f.mgi_accession_id                { Factory.next(:mgi_accession_id) }
  f.sequence(:project_design_id)    { |n| "design id #{n}"}
  f.sequence(:subtype_description)  { |n| "subtype description #{n}" }
  f.sequence(:cassette)             { |n| "cassette #{n}"}
  f.sequence(:backbone)             { |n| "backbone #{n}"}

  f.assembly       "NCBIM37"
  f.chromosome     { [("1".."19").to_a + ['X', 'Y', 'MT']].flatten[rand(22)] }
  f.strand         { ['+', '-'][rand(2)] }
  f.mutation_method { MutationMethod.all[rand(MutationMethod.all.count)] }
  f.mutation_type    { MutationType.all[rand(MutationType.all.count)]  }
  f.mutation_subtype { MutationSubtype.all[rand(MutationSubtype.all.count)]  }
  f.cassette_type  { ['Promotorless','Promotor Driven'][rand(2)] }

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
    if allele.mutation_type.knock_out?
      case allele.strand
        when '+' then 100
        when '-' then 70
      end
    end
  end

  f.loxp_end do |allele|
    if allele.mutation_type.knock_out?
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
  f.association :pipeline, :factory => :pipeline
  f.association :allele, :factory => :allele
end

Factory.define :invalid_targeting_vector, :class => TargetingVector do |f|
end

##
## ES Cells
##

Factory.define :es_cell do |f|
  f.name                { Factory.next(:epd_plate_name) }
  f.parental_cell_line  { ['JM8 parental', 'JM8.F6', 'JM8.N19'][rand(3)] }
  f.mgi_allele_id       { Factory.next(:mgi_allele_id) }

  ikmc_project_id = Factory.next( :ikmc_project_id )

  f.association :pipeline, :factory => :pipeline
  f.association :allele, :factory => :allele
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
## EsCellQcConflict
##

Factory.define :es_cell_qc_conflict do |f|
  qc_field  = ESCELL_QC_OPTIONS.keys[ rand(ESCELL_QC_OPTIONS.size) - 1 ]
  qc_values = ESCELL_QC_OPTIONS[qc_field][:values]

  current_result  = qc_values.first
  proposed_result = qc_values[ rand(qc_values.size - 1) + 1 ]

  f.qc_field        { qc_field.to_s }
  f.proposed_result { proposed_result }

  f.es_cell { |conflict|
    conflict.association( :es_cell, {
      qc_field.to_sym => current_result
    })
  }
end

##
## GenBank files
##

Factory.define :genbank_file do |f|
  f.sequence(:escell_clone)       { |n| "ES Cell clone file #{n}" }
  f.sequence(:targeting_vector)   { |n| "Targeting vector file #{n}" }

  f.association :allele, :factory => :allele
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