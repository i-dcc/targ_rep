require 'test_helper'

class MutationSubTypeTest < ActiveSupport::TestCase
  should have_many(:allele)
  should validate_uniqueness_of(:name)
  should validate_uniqueness_of(:code)
  should validate_presence_of(:name)
  should validate_presence_of(:code)
end