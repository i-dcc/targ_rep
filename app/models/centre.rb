class Centre < ActiveRecord::Base
  #has_many :distribution_qcs, :class_name => "DistributionQc", :foreign_key => "centre_id"
  #has_many :users, :class_name => "User", :foreign_key => "centre_id"

  validates_uniqueness_of :name, :message => 'This Centre name has already been taken'
  validates_presence_of   :name
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
