require 'test_helper'

class MutationMethodTest < ActiveSupport::TestCase
  should have_many(:allele)
end