class AddMoreDistributionEscellFields < ActiveRecord::Migration
  def self.up
    add_column :es_cells, :distribution_qc_three_prime_lr_pcr, :string
    add_column :es_cells, :distribution_qc_thawing, :string
  end

  def self.down
    remove_column :es_cells, :distribution_qc_thawing
    remove_column :es_cells, :distribution_qc_three_prime_lr_pcr
  end
end
