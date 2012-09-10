require 'test_helper'

class SolrUpdate::AlleleUpdaterTest < ActiveSupport::TestCase
  context 'SolrUpdate::AlleleUpdater' do

    should 'delete and then recreate Solr docs for allele when allele is updated'

    should 'delete Solr docs for allele when allele is deleted'

  end
end
