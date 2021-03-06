class FeedsController < ApplicationController
  before_action :set_feed, only: [:reload, :edit, :update]
  before_action :set_active_feed, only: [:show]
  before_action :require_admin, except: [:show, :reload]
  before_action :require_admin_or_reload_key, only: [:reload]

  def index
    @feeds = Feed.order('inactive, title')
  end

  def show
    save_statistics(@feed) if request_from_sparkle?

    @feed.load_if_needed

    if @feed.contents
      render body: @feed.contents
    else
      head :not_found
    end
  end

  def reload
    @feed.load_contents

    if request.xhr?
      render partial: 'feed', locals: { feed: @feed }
    else
      redirect_to feeds_path
    end
  end

  def new
    @feed = Feed.new
  end

  def create
    @feed = Feed.new(feed_params)

    if @feed.save
      @feed.load_contents
      redirect_to feeds_path, notice: "Feed '#{@feed.title}' was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @feed.update_attributes(feed_params)
      @feed.load_if_needed
      redirect_to feeds_path, notice: "Feed '#{@feed.title}' was successfully updated."
    else
      render :edit
    end
  end


  private

  def feed_params
    params.require(:feed).permit(:title, :name, :url, :public_stats, :public_counts, :inactive)
  end

  def set_feed
    @feed = Feed.find_by_name!(params[:id])
  end

  def set_active_feed
    @feed = Feed.active.find_by_name!(params[:id])
  end

  def require_admin_or_reload_key
    reload_key = Rails.application.secrets.reload_key
    require_admin unless reload_key.present? && request.headers['HTTP_X_RELOAD_KEY'] == reload_key
  end

  def request_from_sparkle?
    request.user_agent.present? && request.user_agent =~ %r(Sparkle/)
  end

  def save_statistics(feed)
    StatisticSaver.new(feed).save_params(request.params, request.user_agent)
  end
end
