class FeedsController < ApplicationController
  def index
    @feeds = Feed.all_feeds
  end

  def show
    @feed = Feed.get_by_name(params[:id])

    save_statistics(@feed) if request_from_sparkle?

    if @feed.contents
      render :body => @feed.contents
    else
      head :not_found
    end
  end

  def new
    @feed = Feed.new
  end

  def create
    @feed = Feed.new(feed_params)

    if @feed.save
      redirect_to feeds_path, notice: 'Feed was successfully created.'
    else
      render :new
    end
  end


  private

  def feed_params
    params.require(:feed).permit(:title, :name, :url)
  end

  def request_from_sparkle?
    request.user_agent.present? && request.user_agent =~ %r(Sparkle/)
  end

  def save_statistics(feed)
    now = Time.now
    feed.save_params(now, request.params)
    feed.save_param(now, 'appVersionShort', request.user_agent.split(' ').first.split('/').last)
  end
end
