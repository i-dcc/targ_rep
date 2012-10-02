require 'test_helper'

class MutationSubTypeTest < ActiveSupport::TestCase
  should have_many(:allele)
end