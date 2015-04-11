class FeedsController < ApplicationController
  before_action :set_feed, only: [:show, :reload, :edit, :update]
  before_action :require_admin, except: :show

  def index
    @feeds = Feed.all_feeds
  end

  def show
    save_statistics(@feed) if request_from_sparkle?

    if @feed.contents
      render :body => @feed.contents
    else
      head :not_found
    end
  end

  def reload
    @feed.reload
    redirect_to feeds_path
  rescue Exception
    redirect_to feeds_path
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

  def edit
  end

  def update
    if @feed.update_attributes(feed_params)
      redirect_to feeds_path, notice: 'Feed was successfully updated.'
    else
      render :edit
    end
  end


  private

  def feed_params
    params.require(:feed).permit(:title, :name, :url)
  end

  def set_feed
    @feed = Feed.get_by_name(params[:id])
  end

  def request_from_sparkle?
    request.user_agent.present? && request.user_agent =~ %r(Sparkle/)
  end

  def save_statistics(feed)
    feed.save_params(Time.now, request.params, request.user_agent)
  end
end
