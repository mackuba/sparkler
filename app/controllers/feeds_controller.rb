class FeedsController < ApplicationController
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
    feed.save_params(Time.now, request.params, request.user_agent)
  end
end
