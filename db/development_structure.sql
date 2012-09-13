CREATE TABLE `alleles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `assembly` varchar(50) NOT NULL DEFAULT 'NCBIM37',
  `chromosome` varchar(2) NOT NULL,
  `strand` varchar(1) NOT NULL,
  `mgi_accession_id` varchar(50) NOT NULL,
  `homology_arm_start` int(11) NOT NULL,
  `homology_arm_end` int(11) NOT NULL,
  `loxp_start` int(11) DEFAULT NULL,
  `loxp_end` int(11) DEFAULT NULL,
  `cassette_start` int(11) DEFAULT NULL,
  `cassette_end` int(11) DEFAULT NULL,
  `cassette` varchar(100) DEFAULT NULL,
  `backbone` varchar(100) DEFAULT NULL,
  `design_type` varchar(255) NOT NULL,
  `design_subtype` varchar(255) DEFAULT NULL,
  `subtype_description` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `floxed_start_exon` varchar(255) DEFAULT NULL,
  `floxed_end_exon` varchar(255) DEFAULT NULL,
  `project_design_id` int(11) DEFAULT NULL,
  `mutation_type` varchar(255) DEFAULT NULL,
  `mutation_subtype` varchar(255) DEFAULT NULL,
  `mutation_method` varchar(255) DEFAULT NULL,
  `reporter` varchar(255) DEFAULT NULL,
  `cassette_type` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_mol_struct` (`mgi_accession_id`,`project_design_id`,`assembly`,`chromosome`,`strand`,`homology_arm_start`,`homology_arm_end`,`cassette_start`,`cassette_end`,`loxp_start`,`loxp_end`,`cassette`,`backbone`),
  KEY `index_molecular_structures_on_mgi_accession_id` (`mgi_accession_id`)
) ENGINE=InnoDB AUTO_INCREMENT=40880 DEFAULT CHARSET=latin1;

CREATE TABLE `audits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `auditable_id` int(11) DEFAULT NULL,
  `auditable_type` varchar(255) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `user_type` varchar(255) DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `changes` text,
  `version` int(11) DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `auditable_index` (`auditable_id`,`auditable_type`),
  KEY `user_index` (`user_id`,`user_type`),
  KEY `index_audits_on_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=2777212 DEFAULT CHARSET=latin1;

CREATE TABLE `es_cell_qc_conflicts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `es_cell_id` int(11) DEFAULT NULL,
  `qc_field` varchar(255) NOT NULL,
  `current_result` varchar(255) NOT NULL,
  `proposed_result` varchar(255) NOT NULL,
  `comment` text,
  `created_by` int(11) DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `es_cell_qc_conflicts_es_cell_id_fk` (`es_cell_id`),
  CONSTRAINT `es_cell_qc_conflicts_es_cell_id_fk` FOREIGN KEY (`es_cell_id`) REFERENCES `es_cells` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `es_cells` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `allele_id` int(11) NOT NULL,
  `targeting_vector_id` int(11) DEFAULT NULL,
  `parental_cell_line` varchar(255) DEFAULT NULL,
  `allele_symbol_superscript` varchar(255) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `comment` varchar(255) DEFAULT NULL,
  `contact` varchar(255) DEFAULT NULL,
  `production_qc_five_prime_screen` varchar(255) DEFAULT NULL,
  `distribution_qc_five_prime_sr_pcr` varchar(255) DEFAULT NULL,
  `production_qc_three_prime_screen` varchar(255) DEFAULT NULL,
  `distribution_qc_three_prime_sr_pcr` varchar(255) DEFAULT NULL,
  `ikmc_project_id` varchar(255) DEFAULT NULL,
  `user_qc_map_test` varchar(255) DEFAULT NULL,
  `user_qc_karyotype` varchar(255) DEFAULT NULL,
  `user_qc_tv_backbone_assay` varchar(255) DEFAULT NULL,
  `user_qc_loxp_confirmation` varchar(255) DEFAULT NULL,
  `user_qc_southern_blot` varchar(255) DEFAULT NULL,
  `user_qc_loss_of_wt_allele` varchar(255) DEFAULT NULL,
  `user_qc_neo_count_qpcr` varchar(255) DEFAULT NULL,
  `user_qc_lacz_sr_pcr` varchar(255) DEFAULT NULL,
  `user_qc_mutant_specific_sr_pcr` varchar(255) DEFAULT NULL,
  `user_qc_five_prime_cassette_integrity` varchar(255) DEFAULT NULL,
  `user_qc_neo_sr_pcr` varchar(255) DEFAULT NULL,
  `user_qc_five_prime_lr_pcr` varchar(255) DEFAULT NULL,
  `user_qc_three_prime_lr_pcr` varchar(255) DEFAULT NULL,
  `user_qc_comment` text,
  `production_qc_loxp_screen` varchar(255) DEFAULT NULL,
  `production_qc_loss_of_allele` varchar(255) DEFAULT NULL,
  `production_qc_vector_integrity` varchar(255) DEFAULT NULL,
  `distribution_qc_karyotype_low` float DEFAULT NULL,
  `distribution_qc_karyotype_high` float DEFAULT NULL,
  `distribution_qc_copy_number` varchar(255) DEFAULT NULL,
  `distribution_qc_five_prime_lr_pcr` varchar(255) DEFAULT NULL,
  `distribution_qc_three_prime_lr_pcr` varchar(255) DEFAULT NULL,
  `distribution_qc_thawing` varchar(255) DEFAULT NULL,
  `mgi_allele_id` varchar(50) DEFAULT NULL,
  `pipeline_id` int(11) DEFAULT NULL,
  `report_to_public` tinyint(1) NOT NULL DEFAULT '1',
  `strain` varchar(25) DEFAULT NULL,
  `distribution_qc_loa` varchar(4) DEFAULT NULL,
  `distribution_qc_loxp` varchar(4) DEFAULT NULL,
  `distribution_qc_lacz` varchar(4) DEFAULT NULL,
  `distribution_qc_chr1` varchar(4) DEFAULT NULL,
  `distribution_qc_chr8a` varchar(4) DEFAULT NULL,
  `distribution_qc_chr8b` varchar(4) DEFAULT NULL,
  `distribution_qc_chr11a` varchar(4) DEFAULT NULL,
  `distribution_qc_chr11b` varchar(4) DEFAULT NULL,
  `distribution_qc_chry` varchar(4) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_es_cells_on_name` (`name`),
  KEY `es_cells_allele_id_fk` (`allele_id`),
  KEY `es_cells_pipeline_id_fk` (`pipeline_id`),
  CONSTRAINT `es_cells_allele_id_fk` FOREIGN KEY (`allele_id`) REFERENCES `alleles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `es_cells_pipeline_id_fk` FOREIGN KEY (`pipeline_id`) REFERENCES `pipelines` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=234270 DEFAULT CHARSET=latin1;

CREATE TABLE `genbank_files` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `allele_id` int(11) NOT NULL,
  `escell_clone` longtext,
  `targeting_vector` longtext,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `genbank_files_allele_id_fk` (`allele_id`),
  CONSTRAINT `genbank_files_allele_id_fk` FOREIGN KEY (`allele_id`) REFERENCES `alleles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=42307 DEFAULT CHARSET=latin1;

CREATE TABLE `pipelines` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_pipelines_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1;

CREATE TABLE `qc_field_descriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `qc_field` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `url` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_qc_field_descriptions_on_qc_field` (`qc_field`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `solr_update_solr_commands` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `data` text COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `targeting_vectors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `allele_id` int(11) NOT NULL,
  `ikmc_project_id` varchar(255) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `intermediate_vector` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `report_to_public` tinyint(1) NOT NULL DEFAULT '1',
  `pipeline_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_targvec` (`name`),
  KEY `targeting_vectors_allele_id_fk` (`allele_id`),
  KEY `targeting_vectors_pipeline_id_fk` (`pipeline_id`),
  CONSTRAINT `targeting_vectors_allele_id_fk` FOREIGN KEY (`allele_id`) REFERENCES `alleles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `targeting_vectors_pipeline_id_fk` FOREIGN KEY (`pipeline_id`) REFERENCES `pipelines` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=181949 DEFAULT CHARSET=latin1;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `crypted_password` varchar(255) DEFAULT NULL,
  `password_salt` varchar(255) DEFAULT NULL,
  `persistence_token` varchar(255) DEFAULT NULL,
  `last_login_at` datetime DEFAULT NULL,
  `is_admin` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `login_count` int(11) NOT NULL DEFAULT '0',
  `failed_login_count` int(11) NOT NULL DEFAULT '0',
  `last_request_at` datetime DEFAULT NULL,
  `current_login_at` datetime DEFAULT NULL,
  `current_login_ip` varchar(255) DEFAULT NULL,
  `last_login_ip` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=latin1;

INSERT INTO schema_migrations (version) VALUES ('20091119090001');

INSERT INTO schema_migrations (version) VALUES ('20091119090002');

INSERT INTO schema_migrations (version) VALUES ('20091119090003');

INSERT INTO schema_migrations (version) VALUES ('20091119090004');

INSERT INTO schema_migrations (version) VALUES ('20091119090005');

INSERT INTO schema_migrations (version) VALUES ('20091119090006');

INSERT INTO schema_migrations (version) VALUES ('20091119090007');

INSERT INTO schema_migrations (version) VALUES ('20100118090008');

INSERT INTO schema_migrations (version) VALUES ('20100202105513');

INSERT INTO schema_migrations (version) VALUES ('20100208110320');

INSERT INTO schema_migrations (version) VALUES ('20100217143225');

INSERT INTO schema_migrations (version) VALUES ('20100218101736');

INSERT INTO schema_migrations (version) VALUES ('20100315113400');

INSERT INTO schema_migrations (version) VALUES ('20100317140514');

INSERT INTO schema_migrations (version) VALUES ('20100521095311');

INSERT INTO schema_migrations (version) VALUES ('20100723094719');

INSERT INTO schema_migrations (version) VALUES ('20100726120958');

INSERT INTO schema_migrations (version) VALUES ('20100727154252');

INSERT INTO schema_migrations (version) VALUES ('20100806085214');

INSERT INTO schema_migrations (version) VALUES ('20100806150242');

INSERT INTO schema_migrations (version) VALUES ('20100817132800');

INSERT INTO schema_migrations (version) VALUES ('20101001095540');

INSERT INTO schema_migrations (version) VALUES ('20101019153007');

INSERT INTO schema_migrations (version) VALUES ('20101123153046');

INSERT INTO schema_migrations (version) VALUES ('20101126085942');

INSERT INTO schema_migrations (version) VALUES ('20101201091851');

INSERT INTO schema_migrations (version) VALUES ('20110307130556');

INSERT INTO schema_migrations (version) VALUES ('20110322154912');

INSERT INTO schema_migrations (version) VALUES ('20110701094136');

INSERT INTO schema_migrations (version) VALUES ('20110707091231');

INSERT INTO schema_migrations (version) VALUES ('20110719134537');

INSERT INTO schema_migrations (version) VALUES ('20120228101846');

INSERT INTO schema_migrations (version) VALUES ('20120906111517');