class Option < ApplicationRecord
  belongs_to :property
  validates_presence_of :name
end
