require 'rubygems'
require 'bundler'
require 'yaml'

environment = ENV['RACK_ENV'] || 'development'

Bundler.require

yaml = YAML.load(File.read("config/database.yml"))

ActiveRecord::Base.logger = Logger.new(STDOUT) unless defined?(Rake)
ActiveRecord::Base.configurations = yaml.stringify_keys
ActiveRecord::Base.establish_connection(environment.to_sym)

require_relative 'models/feed'
require_relative 'models/property'
require_relative 'models/value'
require_relative 'models/statistic'
require_relative 'sparkler'
