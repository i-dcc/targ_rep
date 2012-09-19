class CreateSolrUpdateQueueItems < ActiveRecord::Migration
  def self.up
    create_table :solr_update_queue_items do |table|
      table.timestamps
      table.integer :allele_id, :null => false
      table.column :command_type, "ENUM('update', 'delete')"
    end
  end

  def self.down
    drop_table :solr_update_queue_items
  end
end
