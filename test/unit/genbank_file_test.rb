require 'test_helper'

class GenbankFileTest < ActiveSupport::TestCase
  should belong_to(:molecular_structure)
end
