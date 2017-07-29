class Statistic < ApplicationRecord
  belongs_to :feed
  belongs_to :property
  belongs_to :option
end
