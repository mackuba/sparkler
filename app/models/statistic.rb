class Statistic < ActiveRecord::Base
  belongs_to :feed
  belongs_to :property
  belongs_to :value
end
