class StatisticsController < ApplicationController
  before_action :set_feed

  def index
    require_admin unless @feed.public_stats

    @include_counts = @feed.public_counts || logged_in?
    @report = FeedReport.new(@feed, include_counts: @include_counts)
  end

  private

  def set_feed
    @feed = Feed.active.find_by_name!(params[:feed_id])
  end
end
