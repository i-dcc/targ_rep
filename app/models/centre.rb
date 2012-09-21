class Centre < ActiveRecord::Base
  has_many :distribution_qcs
end

# == Schema Information
#
# Table name: centres
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#
