class SolrUpdate::SolrCommand < ActiveRecord::Base
  set_table_name :solr_updating_solr_commands
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

