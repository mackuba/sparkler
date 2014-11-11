require 'open-uri'

class Feed < ActiveRecord::Base
  has_many :statistics
  validates_presence_of :title, :name, :url

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
end
