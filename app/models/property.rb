class Property < ActiveRecord::Base
  has_many :options
  validates_presence_of :name
end
