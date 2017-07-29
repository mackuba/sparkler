class Property < ApplicationRecord
  has_many :options
  validates_presence_of :name
end
