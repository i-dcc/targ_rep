class AddDisplayToTargetingVector < ActiveRecord::Migration
  def self.up
    add_column :targeting_vectors, :display, :boolean, :default => true
  end

  def self.down
    remove_column :targeting_vectors, :display
  end
end
