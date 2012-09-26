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
    Centre.create!(:id => 2, :name => "UCD") if ! Centre.find_by_name "UCD"
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

  end

  def self.down
    drop_table :distribution_qcs

#    execute "delete from distribution_qcs"

  end
end
