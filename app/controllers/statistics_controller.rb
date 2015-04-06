class StatisticsController < ApplicationController
  before_action :set_feed

  def index
    @report = FeedReport.new(@feed)
  end

  private

  def set_feed
    @feed = Feed.get_by_name(params[:feed_id])
  end
end
