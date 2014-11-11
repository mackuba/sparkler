require 'open-uri'

class Feed < ActiveRecord::Base
  has_many :statistics
  validates_presence_of :title, :name, :url

  def title=(title)
    write_attribute :name, title.downcase.gsub(/\W+/, '_') if title
    write_attribute :title, title
  end

  def contents
    @contents ||= open(url).read
  end
end
