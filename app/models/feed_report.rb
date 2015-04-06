class FeedReport
  PROPERTIES = {
    'osVersion' => {
      :title => 'OS Version',
      :group_by => lambda { |v| v.split('.').first(2).join('.') },
      :sort_by => lambda { |v| v.split('.').map(&:to_i) }
    },
    'model' => {
      :title => 'Mac Model'
    },
    'cputype' => {
      :title => 'CPU Type',
      :values => {
        '7' => 'Intel',
        '18' => 'PowerPC'
      }
    },
    'cpu64bit' => {
      :title => 'CPU Bits',
      :values => {
        '0' => '32-bit',
        '1' => '64-bit'
      }
    },
    'ncpu' => {
      :title => 'Number of CPUs'
    },
    'cpuFreqMHz' => {
      :title => 'CPU Frequency [MHz]'
    },
    'ramMB' => {
      :title => 'Amount of RAM [MB]'
    },
    'appVersionShort' => {
      :title => 'App Version',
      :sort_by => lambda { |v| v.split('.').map(&:to_i) }
    },
    'lang' => {
      :title => 'Locale'
    }
  }

  attr_reader :months, :properties

  def initialize(feed)
    @feed = feed

    @months = feed.statistics.select('DISTINCT year, month').order('year, month').map { |r| [r.year, r.month] }
    @properties = PROPERTIES.map { |name, data| [data[:title], Property.find_or_create_by(name: name)] }

    calculate_stats
    calculate_values
  end

  def calculate_stats
    @stats = {}

    @feed.statistics.each do |stat|
      property_stats = @stats[stat.property_id] ||= {}
      value_stats = property_stats[stat.value_id] ||= {}
      year_stats = value_stats[stat.year] ||= {}
      year_stats[stat.month] = stat.counter
    end
  end

  def count_for(property_id, value_id, year, month)
    property_stats = @stats[property_id] || {}
    value_stats = property_stats[value_id] || {}
    year_stats = value_stats[year] || {}
    year_stats[month] || 0
  end

  def calculate_values
    @values = {}

    @properties.each do |title, property|
      value_title_map = PROPERTIES[property.name][:values]
      grouping = PROPERTIES[property.name][:group_by]
      sorting = PROPERTIES[property.name][:sort_by] || lambda { |title| [title.to_i, title.downcase] }

      value_ids_for_title = {}

      property.values.each do |value|
        title = value_title_map && value_title_map[value.name] || value.name
        grouped_title = grouping ? grouping.call(title) : title
        value_ids_for_title[grouped_title] ||= []
        value_ids_for_title[grouped_title] << value.id
      end

      data_lines = value_ids_for_title.keys.sort_by(&sorting).map do |title|
        counts = @months.map do |y, m|
          value_ids_for_title[title].sum { |value_id| count_for(property.id, value_id, y, m) }
        end

        [title, counts]
      end

      @values[property] = data_lines.reject { |title, counts| counts.sum == 0 }
    end
  end

  def values_for_property(property)
    @values[property]
  end
end
