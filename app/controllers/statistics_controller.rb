class StatisticsController < ApplicationController
  before_action :set_feed

  def index
    @properties = Property::PROPERTY_TITLES.map do |title, property_name|
      [title, Property.find_by_name(property_name)]
    end

    @months = @feed.months_with_data.last(18)
  end

  private

  def set_feed
    @feed = Feed.get_by_name(params[:feed_id])
  end
end
