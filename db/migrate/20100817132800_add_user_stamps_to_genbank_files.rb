class AddUserStampsToGenbankFiles < ActiveRecord::Migration
  def self.up
    add_column :genbank_files, :created_by, :integer
    add_column :genbank_files, :updated_by, :integer
  end

  def self.down
    remove_column :genbank_files, :updated_by
    remove_column :genbank_files, :created_by
  end
end