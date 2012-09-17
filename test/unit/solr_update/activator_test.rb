require 'test_helper'

class SolrUpdate::ObserverTest < ActiveSupport::TestCase
  context 'SolrUpdate::Activator' do

    should 'activate the update of an allele\'s solr docs' do
      command = stub('solr_command')
      allele = stub('allele')
      seq = sequence('seq')
      allele.expects(:reload).in_sequence(seq)
      SolrUpdate::SolrCommandFactory.expects(:create_solr_command).with(allele).returns(command).in_sequence(seq)
      SolrUpdate::Queue.expects(:add).with(command)

      SolrUpdate::Activator.update_allele_solr_docs(allele)
    end

  end
end
