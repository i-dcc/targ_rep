require 'test_helper'

class QcFieldDescriptionsTest < ActiveSupport::TestCase
  should validate_uniqueness_of(:qc_field)

  should validate_presence_of(:qc_field)
  should validate_presence_of(:description)
end
