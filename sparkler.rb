require 'open-uri'
require 'mongo'
require 'rack'

FEEDS = {
  'gitifier' => 'https://github.com/psionides/gitifier/raw/master/Sparkle/gitifier_appcast.xml'
}

class Sparkler
  def initialize
    @feed_cache = {}
    @db = Mongo::Connection.new.db("sparkler")
  end

  def call(env)
    request = Rack::Request.new(env)

    if request.path_info =~ %r(^/feed/(\w+)$)
      app = $1
      if FEEDS[app]
        month = Time.now.strftime "%Y-%m"
        request.params['userAgent'] = env["HTTP_USER_AGENT"].to_s.split(/\//).first
        request.params.delete('appName')
        request.params.each do |field, value|
          value = value.gsub(/\./, '_')
          @db.collection(app).update(
            { '_field' => field, '_month' => month },
            { '$inc' => { value => 1 }},
            :upsert => true
          )
        end

        @feed_cache[app] = open(FEEDS[app]).read unless @feed_cache[app]

        success @feed_cache[app]
      else
        not_found
      end
    else
      not_found
    end
  end

  def success(html)
    Rack::Response.new(html).to_a
  end

  def not_found
    Rack::Response.new("", 404).to_a
  end
end
