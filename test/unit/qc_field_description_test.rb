require 'test_helper'

class QcFieldDescriptionTest < ActiveSupport::TestCase
  setup do
    Factory.create( :qc_field_description )
  end
  
  should validate_presence_of(:qc_field)
  should validate_presence_of(:description)
end

# == Schema Information
#
# Table name: qc_field_descriptions
#
#  id          :integer(4)      not null, primary key
#  qc_field    :string(255)     not null
#  description :text            default(""), not null
#  url         :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

