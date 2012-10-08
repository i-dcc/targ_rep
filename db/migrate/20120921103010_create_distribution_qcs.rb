class CreateDistributionQcs < ActiveRecord::Migration
  def self.up
    create_table :distribution_qcs do |t|
      t.string :five_prime_sr_pcr
      t.string :three_prime_sr_pcr
      t.float :karyotype_low
      t.float :karyotype_high
      t.string :copy_number
      t.string :five_prime_lr_pcr
      t.string :three_prime_lr_pcr
      t.string :thawing
      t.string :loa
      t.string :loxp
      t.string :lacz
      t.string :chr1
      t.string :chr8a
      t.string :chr8b
      t.string :chr11a
      t.string :chr11b
      t.string :chry
      t.references :es_cell
      t.references :centre

      t.timestamps
    end

# TODO: remove me!
    Centre.create!(:id => 1, :name => "WTSI") if ! Centre.find_by_name "WTSI"
    Centre.create!(:id => 2, :name => "KOMP") if ! Centre.find_by_name "KOMP"
    Centre.create!(:id => 3, :name => "EUCOMM") if ! Centre.find_by_name "EUCOMM"

    execute "
      insert into distribution_qcs (five_prime_sr_pcr, three_prime_sr_pcr, karyotype_low, karyotype_high, copy_number, five_prime_lr_pcr, three_prime_lr_pcr,
              thawing, loa, loxp, lacz, chr1, chr8a, chr8b, chr11a, chr11b, chry, es_cell_id, centre_id, created_at, updated_at)
      select  distribution_qc_five_prime_sr_pcr, distribution_qc_three_prime_sr_pcr, distribution_qc_karyotype_low, distribution_qc_karyotype_high,
              distribution_qc_copy_number, distribution_qc_five_prime_lr_pcr, distribution_qc_three_prime_lr_pcr,
              distribution_qc_thawing, distribution_qc_loa, distribution_qc_loxp, distribution_qc_lacz,
              distribution_qc_chr1, distribution_qc_chr8a, distribution_qc_chr8b, distribution_qc_chr11a, distribution_qc_chr11b,
              distribution_qc_chry, es_cells.id, centres.id, NOW(), NOW() from es_cells, centres
    "

    #execute "
    #  insert into distribution_qcs (five_prime_sr_pcr, three_prime_sr_pcr, karyotype_low, karyotype_high, copy_number, five_prime_lr_pcr, three_prime_lr_pcr,
    #          thawing, loa, loxp, lacz, chr1, chr8a, chr8b, chr11a, chr11b, chry, es_cell_id, centre_id, created_at, updated_at)
    #  select  distribution_qc_five_prime_sr_pcr, distribution_qc_three_prime_sr_pcr, distribution_qc_karyotype_low, distribution_qc_karyotype_high,
    #          distribution_qc_copy_number, distribution_qc_five_prime_lr_pcr, distribution_qc_three_prime_lr_pcr,
    #          distribution_qc_thawing, distribution_qc_loa, distribution_qc_loxp, distribution_qc_lacz,
    #          distribution_qc_chr1, distribution_qc_chr8a, distribution_qc_chr8b, distribution_qc_chr11a, distribution_qc_chr11b,
    #          distribution_qc_chry, es_cells.id, centres.id, NOW(), NOW() from es_cells, centres, pipelines
    #          where centres.name = 'KOMP' and pipelines.name in ('KOMP-CSD', 'KOMP-Regeneron') and pipelines.id = es_cells.pipeline_id
    #"
    #
    #execute "
    #  insert into distribution_qcs (five_prime_sr_pcr, three_prime_sr_pcr, karyotype_low, karyotype_high, copy_number, five_prime_lr_pcr, three_prime_lr_pcr,
    #          thawing, loa, loxp, lacz, chr1, chr8a, chr8b, chr11a, chr11b, chry, es_cell_id, centre_id, created_at, updated_at)
    #  select  distribution_qc_five_prime_sr_pcr, distribution_qc_three_prime_sr_pcr, distribution_qc_karyotype_low, distribution_qc_karyotype_high,
    #          distribution_qc_copy_number, distribution_qc_five_prime_lr_pcr, distribution_qc_three_prime_lr_pcr,
    #          distribution_qc_thawing, distribution_qc_loa, distribution_qc_loxp, distribution_qc_lacz,
    #          distribution_qc_chr1, distribution_qc_chr8a, distribution_qc_chr8b, distribution_qc_chr11a, distribution_qc_chr11b,
    #          distribution_qc_chry, es_cells.id, centres.id, NOW(), NOW() from es_cells, centres, pipelines
    #          where centres.name = 'EUCOMM' and pipelines.name in ('EUCOMM') and pipelines.id = es_cells.pipeline_id
    #"

    #remove_column :es_cells, :distribution_qc_copy_number
    #remove_column :es_cells, :distribution_qc_karyotype_high
    #remove_column :es_cells, :distribution_qc_karyotype_low
    #remove_column :es_cells, :distribution_qc_five_prime_lr_pcr
    #remove_column :es_cells, :distribution_qc_thawing
    #remove_column :es_cells, :distribution_qc_three_prime_lr_pcr
    #remove_column :es_cells, :distribution_qc_loa
    #remove_column :es_cells, :distribution_qc_loxp
    #remove_column :es_cells, :distribution_qc_lacz
    #remove_column :es_cells, :distribution_qc_chr1
    #remove_column :es_cells, :distribution_qc_chr8a
    #remove_column :es_cells, :distribution_qc_chr8b
    #remove_column :es_cells, :distribution_qc_chr11a
    #remove_column :es_cells, :distribution_qc_chr11b
    #remove_column :es_cells, :distribution_qc_chry

  end

  def self.down
    drop_table :distribution_qcs

#    execute "delete from distribution_qcs"

  end
end
