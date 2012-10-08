class CreateSolrUpdateQueueItems < ActiveRecord::Migration
  def self.up
    create_table :solr_update_queue_items do |table|
      table.timestamps
      table.integer :allele_id, :null => false
      table.column :action, "ENUM('update', 'delete')"
    end
    add_index :solr_update_queue_items, :allele_id, :unique => true
  end

  def self.down
    drop_table :solr_update_queue_items
  end
end
