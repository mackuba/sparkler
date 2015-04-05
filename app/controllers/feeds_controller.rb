class FeedsController < ApplicationController
  def index
    @feeds = Feed.all_feeds
  end

  def show
    @feed = Feed.get_by_name(params[:id])

    save_statistics(@feed) if request_from_sparkle?

    if @feed.contents
      render :text => @feed.contents
    else
      head :not_found
    end
  end


  private

  def request_from_sparkle?
    request.user_agent.present? && request.user_agent =~ %r(Sparkle/)
  end

  def save_statistics(feed)
    now = Time.now
    feed.save_params(now, request.params)
    feed.save_param(now, 'appVersionShort', request.user_agent.split(' ').first.split('/').last)
  end
end
