class SolrUpdate::SolrCommand < ActiveRecord::Base
  set_table_name :solr_update_solr_commands

  def self.earliest_first
    return self.find(:all, :order => 'created_at asc').map(&:data)
  end

  def self.add(doc)
    self.create!(:data => doc)
  end
end

# == Schema Information
#
# Table name: solr_updating_solr_commands
#
#  id         :integer(4)      not null, primary key
#  data       :text            default(""), not null
#  created_at :datetime
#  updated_at :datetime
#

