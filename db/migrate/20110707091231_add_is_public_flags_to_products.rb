class AddIsPublicFlagsToProducts < ActiveRecord::Migration
  def self.up
    TargetingVector.all( :conditions => { :display => nil } ).each do |tv|
      tv.display = false
      tv.save
    end
    
    rename_column :targeting_vectors, :display, :report_to_public
    change_column :targeting_vectors, :report_to_public, :boolean, :default => true, :null => false
    
    add_column :es_cells, :report_to_public, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :es_cells, :report_to_public
    rename_column :targeting_vectors, :report_to_public, :display
  end
end