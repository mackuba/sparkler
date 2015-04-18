require 'open-uri'

class Feed < ActiveRecord::Base
  has_many :statistics
  validates_presence_of :title, :name, :url

  after_create :add_to_list

  attr_reader :last_version, :load_error

  def self.all_feeds
    @@feeds ||= Feed.all.to_a
  end

  def self.get_by_name(name)
    feed = all_feeds.detect { |f| f.name == name }
    feed or raise ActiveRecord::RecordNotFound.new("Couldn't find Feed with name='#{name}'")
  end

  def to_param
    name
  end

  def add_to_list
    self.class.all_feeds << self
  end

  def contents
    unless @contents
      puts "Reloading feed from #{url}..."
      @contents = open(url).read
      @last_version = version_from_contents(@contents)
      @load_error = nil
    end

    @contents
  rescue OpenURI::HTTPError => error
    puts "Couldn't download feed from #{url}: #{error}"
    @load_error = error
  end

  def loaded?
    @contents.present?
  end

  def reload
    @contents = nil
    contents
  end

  def version_from_contents(contents)
    xml = Nokogiri::XML(contents)
    first_item = xml.css('item').first
    enclosure = first_item && first_item.css('enclosure').first
    enclosure && (enclosure['sparkle:shortVersionString'] || enclosure['sparkle:version'])
  end

  def save_params(timestamp, params, user_agent)
    params = params.clone
    params.delete('appName')
    params.delete('controller')
    params.delete('action')
    params.delete('id')
    subtype = params.delete('cpusubtype')

    params.each do |property_name, option_name|
      save_param(timestamp, property_name, option_name)
    end

    save_param(timestamp, 'appVersionShort', user_agent.split(' ').first.split('/').last)
    save_param(timestamp, 'cpusubtype', "#{params['cputype']}.#{subtype}") if subtype
  end

  def save_param(timestamp, property_name, option_name)
    property = Property.find_or_create_by(name: property_name)
    option = property.options.find_or_create_by(name: option_name)

    statistic = self.statistics.find_or_create_by(
      year: timestamp.year,
      month: timestamp.month,
      property: property,
      option: option
    )

    Statistic.update_counters(statistic.id, counter: 1)
  end
end
