class SolrUpdate::Queue::Item < ActiveRecord::Base
  set_table_name 'solr_update_queue_items'

  def self.add(allele, command_type)
    self.create!(:allele_id => allele.id, :command_type => command_type)
  end

  named_scope :earliest_first, :order => 'solr_update_queue_items.created_at asc'
end
