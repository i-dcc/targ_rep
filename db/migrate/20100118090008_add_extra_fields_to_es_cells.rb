class AddExtraFieldsToEsCells < ActiveRecord::Migration
  def self.up
    add_column    :es_cells, :comment, :string
    add_column    :es_cells, :contact, :string
    add_column    :es_cells, :upper_LR_check, :string
    add_column    :es_cells, :upper_SR_check, :string
    add_column    :es_cells, :lower_LR_check, :string
    add_column    :es_cells, :lower_SR_check, :string
  end
  
  def self.down
    remove_column :es_cells, :comment
    remove_column :es_cells, :contact
    remove_column :es_cells, :upper_LR_check
    remove_column :es_cells, :upper_SR_check
    remove_column :es_cells, :lower_LR_check
    remove_column :es_cells, :lower_SR_check
  end
end
