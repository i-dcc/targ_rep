class QcFieldDescription < ActiveRecord::Base
  validates_uniqueness_of :qc_field
  validates_presence_of :qc_field
  validates_presence_of :description
end
