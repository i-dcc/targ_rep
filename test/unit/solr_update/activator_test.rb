require 'test_helper'

class SolrUpdate::ActivatorTest < ActiveSupport::TestCase
  context 'SolrUpdate::Activator' do

    should 'activate the update of an allele\'s solr docs' do
      command = stub('solr_command')
      allele = stub('allele')
      reloaded_allele = stub('reloaded_allele')

      ::Allele.expects(:find).with(allele).returns(reloaded_allele)
      SolrUpdate::SolrCommandFactory.expects(:create_solr_command_to_update_in_index).with(reloaded_allele).returns(command)
      SolrUpdate::Queue.expects(:add).with(command)

      SolrUpdate::Activator.update_allele_solr_docs(allele)
    end

    should 'activate the deletion of an destroyed allele\'s solr docs' do
      command = stub('solr_command')
      allele = stub('allele')
      SolrUpdate::SolrCommandFactory.expects(:create_solr_command_to_delete_from_index).with(allele).returns(command)
      SolrUpdate::Queue.expects(:add).with(command)

      SolrUpdate::Activator.delete_allele_solr_docs(allele)
    end

  end
end
