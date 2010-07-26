class QcFieldDescriptions < ActiveRecord::Base
  validates_uniqueness_of :qc_field, :on => :create, :message => "must be unique"
  
  validates_presence_of :qc_field,    :on => :create, :message => "can't be blank"
  validates_presence_of :description, :on => :create, :message => "can't be blank"
end
