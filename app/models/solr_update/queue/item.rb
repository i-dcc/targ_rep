class SolrUpdate::Queue::Item < ActiveRecord::Base
  set_table_name 'solr_update_queue_items'

  belongs_to :allele

  def self.add(allele_reference, command_type)
    if allele_reference.kind_of?(Allele)
      allele_reference = {'type' => 'allele', 'id' => allele_reference.id}
    end

    existing = find_by_allele_id(allele_reference['id'])
    existing.destroy if existing
    self.create!(:allele_id => allele_reference['id'], :command_type => command_type)
  end

  def self.process_in_order
    self.earliest_first.each do |item|
      yield({'type' => 'allele', 'id' => item.allele_id}, item.command_type)
      item.destroy
    end
  end

  named_scope :earliest_first, :order => 'solr_update_queue_items.created_at asc'
end
