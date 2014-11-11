require 'json'
require_relative '../init'

records = ARGV.first ? JSON.load(File.read(ARGV.first)) : JSON.load(STDIN)
feed = Feed.first
properties = {}

records.each do |record|
  year, month = record['_month'].split(/-/).map(&:to_i)

  property_name = record['_field']
  property = properties[property_name] ||= Property.find_or_create_by(name: property_name)

  record.reject { |k, v| k.starts_with?('_') }.each do |value_name, count|
    value = property.values.detect { |v| v.name == value_name } || property.values.create(name: value_name)

    statistic = Statistic.find_or_create_by(
      year: year,
      month: month,
      feed: feed,
      property: property,
      value: value
    )

    puts "#{year}/#{month}: #{property.name}: #{value.name} = #{count}"
    statistic.update_attribute :counter, count
  end
end
