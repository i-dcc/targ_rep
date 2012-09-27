require 'test_helper'

class SolrUpdate::CommandFactoryTest < ActiveSupport::TestCase

  context 'SolrUpdate::CommandFactory' do

    context 'when creating SOLR command for an object that was updated' do

      setup do
        fake_docs = [{'thing_doc' => 1}, {'thing_doc' => 2}]
        SolrUpdate::DocFactory.expects(:create).with('type' => 'thing', 'id' => 33).returns(fake_docs)

        @commands_json = SolrUpdate::CommandFactory.create_solr_command_to_update_in_index('type' => 'thing', 'id' => 33)
        @commands = JSON.parse(@commands_json, :object_class => ActiveSupport::OrderedHash)
      end

      should 'delete, add and commit in that order' do
        assert_equal %w{delete add commit}, @commands.keys
      end

      should 'delete all docs for that thing before adding them' do
        assert_equal "type:thing AND id:33", @commands['delete']['query']
      end

      should 'add new docs for that thing' do
        assert_equal [{'thing_doc' => 1}, {'thing_doc' => 2}], @commands['add']
      end

      should 'do a commit after adding new docs' do
        assert_equal({}, @commands['commit'])
      end
    end

    context 'when creating SOLR command for an object that was deleted' do
      setup do
        @commands_json = SolrUpdate::CommandFactory.create_solr_command_to_delete_from_index('type' => 'thing', 'id' => 55)
        @commands = JSON.parse(@commands_json, :object_class => ActiveSupport::OrderedHash)
      end

      should 'delete and commit in that order' do
        assert_equal %w{delete commit}, @commands.keys
      end

      should 'delete all docs for that thing' do
        assert_equal "type:thing AND id:55", @commands['delete']['query']
      end

      should 'do a commit after adding new docs' do
        assert_equal({}, @commands['commit'])
      end
    end

  end
end
