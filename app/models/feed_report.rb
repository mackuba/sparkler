class FeedReport
  PROPERTIES = {
    'model' => {
      :title => 'Mac model'
    },
    'cputype' => {
      :title => 'CPU type',
      :values => {
        '7' => 'Intel',
        '18' => 'PowerPC'
      }
    },
    'cpusubtype' => {
      :title => 'CPU subtype'
    },
    'cpu64bit' => {
      :title => 'CPU bits',
      :values => {
        '0' => '32-bit',
        '1' => '64-bit'
      }
    },
    'ncpu' => {
      :title => 'Number of CPUs'
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

    @values = @properties.map(&:last).reduce({}) do |list, property|
      value_title_map = PROPERTIES[property.name][:values]

      value_list = property.values.map do |value|
        title = value_title_map && value_title_map[value.name] || value.name
        counts = @months.map { |y, m| count_for(property, value, y, m) }
        counts.sum > 0 ? [title, counts] : nil
      end

      sorted_list = value_list.compact.sort_by { |title, counts| [title.to_i, title.downcase] }

      list.update(property => sorted_list)
    end
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

  def count_for(property, value, year, month)
    property_stats = @stats[property.id] || {}
    value_stats = property_stats[value.id] || {}
    year_stats = value_stats[year] || {}
    year_stats[month] || 0
  end

  def values_for_property(property)
    @values[property]
  end
end
