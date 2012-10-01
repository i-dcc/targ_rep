class AddRefForCentresToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :centre_id, :integer
    add_foreign_key :users, :centres
  end

  def self.down
    remove_foreign_key :users, :centres
    remove_column :users, :centre_id
  end
end
