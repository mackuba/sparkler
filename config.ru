File.expand_path('../init', __FILE__)
require 'rack'

run Sparkler.new
puts "Sparkler is online."
