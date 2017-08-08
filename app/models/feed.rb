require 'open-uri'

class Feed < ApplicationRecord
  has_many :statistics
  validates_presence_of :title, :name, :url

  validates_format_of :name, with: %r{\A[a-z0-9_\-\.]+\z}, allow_blank: true,
    message: 'may only contain letters, digits, underscores, hyphens and periods'

  validates_format_of :url, with: %r{\A((http|https|ftp)://|/)}, allow_blank: true

  before_save :reset_if_url_changed

  scope :active, -> { where(inactive: false) }


  def to_param
    name
  end

  def active?
    !inactive
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
  rescue OpenURI::HTTPError, RuntimeError, SocketError, SystemCallError, Nokogiri::XML::XPath::SyntaxError => error
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
    versions = xml.css('item').map { |item| version_from_item(item) }.compact
    versions.map { |v| Gem::Version.new(v) }.sort.reverse.first.try(:to_s)
  end

  def version_from_item(item)
    if version = item.css('sparkle|version').first
      version.text
    elsif enclosure = item.css('enclosure').first
      enclosure['sparkle:shortVersionString'] || enclosure['sparkle:version']
    else
      nil
    end
  end
end
