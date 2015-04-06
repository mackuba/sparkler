require 'open-uri'

class Feed < ActiveRecord::Base
  has_many :statistics
  validates_presence_of :title, :name, :url

  def self.all_feeds
    @@feeds ||= Feed.all.to_a
  end

  def self.get_by_name(name)
    feed = all_feeds.detect { |f| f.name == name }
    feed or raise ActiveRecord::RecordNotFound.new("Couldn't find Feed with name='#{name}'")
  end

  def title=(title)
    write_attribute :name, title.downcase.gsub(/\W+/, '_') if title
    write_attribute :title, title
  end

  def contents
    unless @contents
      puts "Reloading feed from #{url}..."
      @contents = open(url).read
    end

    @contents
  rescue OpenURI::HTTPError => error
    puts "Couldn't download feed from #{url}: #{error}"
  end

  def save_params(timestamp, params, user_agent)
    params = params.clone
    params.delete('appName')
    subtype = params.delete('cpusubtype')

    params.each do |property_name, value_name|
      save_param(timestamp, property_name, value_name)
    end

    save_param(timestamp, 'appVersionShort', user_agent.split(' ').first.split('/').last)
    save_param(timestamp, 'cpusubtype', "#{params['cputype']}.#{subtype}") if subtype
  end

  def save_param(timestamp, property_name, value_name)
    property = Property.find_or_create_by(name: property_name)
    value = property.values.find_or_create_by(name: value_name)

    statistic = self.statistics.find_or_create_by(
      year: timestamp.year,
      month: timestamp.month,
      property: property,
      value: value
    )

    Statistic.update_counters(statistic.id, counter: 1)
  end
end
