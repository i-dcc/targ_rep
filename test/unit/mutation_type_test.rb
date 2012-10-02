require 'test_helper'

class MutationTypeTest < ActiveSupport::TestCase
  should have_many(:allele)
end