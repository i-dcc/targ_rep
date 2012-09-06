class CreateSolrUpdatingSolrCommands < ActiveRecord::Migration
  def self.up
    create_table :solr_updating_solr_commands do |t|
      t.text :data, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :solr_updating_solr_commands
  end
end
