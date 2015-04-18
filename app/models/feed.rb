require 'open-uri'

class Feed < ActiveRecord::Base
  has_many :statistics
  validates_presence_of :title, :name, :url

  before_save :reset_if_url_changed

  def to_param
    name
  end

  def loaded?
    contents.present?
  end

  def load_if_needed
    load_contents unless loaded?
  end

  def load_contents
    logger.info "Reloading feed #{title} from #{url}..."

    text = open(url, :allow_redirections => :safe).read

    self.contents = text
    self.last_version = version_from_contents(text)
    self.load_error = nil
    save!
  rescue OpenURI::HTTPError, RuntimeError, SocketError, SystemCallError => error
    logger.error "Couldn't download feed from #{url}: #{error}"

    self.load_error = error
    save!
  end

  def reset_if_url_changed
    if url_changed?
      self.contents = nil
      self.last_version = nil
      self.load_error = nil
    end
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
