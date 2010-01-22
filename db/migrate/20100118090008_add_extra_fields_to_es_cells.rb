class AddExtraFieldsToEsCells < ActiveRecord::Migration
  def self.up
    add_column    :es_cells, :comment, :string
    add_column    :es_cells, :contact, :string
    add_column    :es_cells, :upper_LR_chk_passed, :integer
    add_column    :es_cells, :upper_SR_chk_passed, :integer
    add_column    :es_cells, :lower_LR_chk_passed, :integer
    add_column    :es_cells, :lower_SR_chk_passed, :integer
  end

  def self.down
    remove_column :es_cells, :comment
    remove_column :es_cells, :contact
    remove_column :es_cells, :upper_LR_chk_passed
    remove_column :es_cells, :upper_SR_chk_passed
    remove_column :es_cells, :lower_LR_chk_passed
    remove_column :es_cells, :lower_SR_chk_passed
  end
end
