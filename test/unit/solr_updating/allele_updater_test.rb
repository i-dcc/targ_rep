require 'test_helper'

class SolrUpdating::AlleleUpdaterTest < ActiveSupport::TestCase
  context 'SolrUpdating::AlleleUpdater' do

    should 'delete and then recreate Solr docs for allele when allele is updated'

    should 'delete Solr docs for allele when allele is deleted'

  end
end
