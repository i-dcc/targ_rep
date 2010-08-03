require 'test_helper'

class ReportsControllerTest < ActionController::TestCase
  setup do
    UserSession.create Factory.build( :user )
    Factory.create( :es_cell )
    Factory.create( :es_cell )
    Factory.create( :es_cell )
  end
  
  should "get index" do
    get :index
    assert_response :success
  end
end
