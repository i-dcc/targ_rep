class AddDistributionQcFivePrimeLrPcrToEsCells < ActiveRecord::Migration
  def self.up
    add_column :es_cells, :distribution_qc_five_prime_lr_pcr, :string
  end

  def self.down
    remove_column :es_cells, :distribution_qc_five_prime_lr_pcr
  end
end
