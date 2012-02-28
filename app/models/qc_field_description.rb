class QcFieldDescription < ActiveRecord::Base
  validates_uniqueness_of :qc_field
  validates_presence_of :qc_field
  validates_presence_of :description
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
# Indexes
#
#  index_qc_field_descriptions_on_qc_field  (qc_field) UNIQUE
#

