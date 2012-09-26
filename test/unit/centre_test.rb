require 'test_helper'

class CentreTest < ActiveSupport::TestCase

  should have_many :distribution_qcs

  should have_db_column(:name).of_type(:string)

  should validate_uniqueness_of :name

  should validate_presence_of :name

end
