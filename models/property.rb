class Property < ActiveRecord::Base
  has_many :values
  validates_presence_of :name
end
