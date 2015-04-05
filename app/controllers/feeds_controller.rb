class FeedsController < ApplicationController
  def show
    @feed = Feed.find_by_name!(params[:id])

    now = Time.now
    year, month = now.year, now.month

    params = request.params.clone
    params['userAgent'] = env["HTTP_USER_AGENT"].to_s.split(/\//).first
    params.delete('appName')

    params.each do |property_name, value_name|
      property = @properties[property_name] ||= Property.find_or_create_by(name: property_name)
      value = property.values.detect { |v| v.name == value_name } || property.values.create(name: value_name)

      statistic = Statistic.find_or_create_by(
        year: year,
        month: month,
        feed: feed,
        property: property,
        value: value
      )

      Statistic.update_counters(statistic.id, counter: 1)
    end

    feed.contents ? success(feed.contents) : not_found
  end
end
