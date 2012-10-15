class SolrUpdate::Queue::Item < ActiveRecord::Base
  set_table_name 'solr_update_queue_items'

  belongs_to :allele

  def reference; {'type' => 'allele', 'id' => allele_id}; end

  def self.add(allele_reference, action)
    if allele_reference.kind_of?(Allele)
      allele_reference = {'type' => 'allele', 'id' => allele_reference.id}
    end

    existing = find_by_allele_id(allele_reference['id'])
    existing.destroy if existing
    self.create!(:allele_id => allele_reference['id'], :action => action)
  end

  def self.process_in_order(args = {})
    args.symbolize_keys!
    self.earliest_first.all(:limit => args[:limit]).each do |item|
      yield item
    end
  end

  named_scope :earliest_first, :order => 'solr_update_queue_items.created_at asc'
end

# == Schema Information
#
# Table name: solr_update_queue_items
#
#  id         :integer(4)      not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  allele_id  :integer(4)      not null
#  action     :string(0)
#
# Indexes
#
#  index_solr_update_queue_items_on_allele_id  (allele_id) UNIQUE
#

