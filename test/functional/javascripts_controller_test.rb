require 'test_helper'

class JavascriptsControllerTest < ActionController::TestCase
  setup do
    user = Factory.create( :user )
    UserSession.create user
  end
  
  teardown do
    session = UserSession.find
    session.destroy
  end
  
  should "allow us to GET /dynamic_esc_qc_conflict_selects" do
    get :dynamic_esc_qc_conflict_selects, :format => "js"
    assert_response :success
  end
end
