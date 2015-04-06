class FeedReport
  REPORTS = {
    'OS Version' => {
      :field => 'osVersion',
      :group_by => lambda { |v| v.split('.').first(2).join('.') },
      :sort_by => lambda { |v| v.split('.').map(&:to_i) }
    },
    'Mac Class' => {
      :field => 'model',
      :group_by => lambda { |v| v[/^[[:alpha:]]+/] },
      :values => {
        'MacBookAir' => 'MacBook Air',
        'MacBookPro' => 'MacBook Pro',
        'Macmini' => 'Mac Mini',
        'MacPro' => 'Mac Pro'
      }
    },
    'Mac Model' => {
      :field => 'model'
    },
    'CPU Type' => {
      :field => 'cputype',
      :values => {
        '7' => 'Intel',
        '18' => 'PowerPC'
      }
    },
    'CPU Bits' => {
      :field => 'cpu64bit',
      :values => {
        '0' => '32-bit',
        '1' => '64-bit'
      }
    },
    'Number of CPUs' => {
      :field => 'ncpu'
    },
    'CPU Frequency' => {
      :field => 'cpuFreqMHz',
      :group_by => lambda { |v|
        mhz = v.to_i
        
        case mhz
        when 0...1500 then "< 1.5 GHz"
        when 1500...2000 then "1.5-1.9 GHz"
        when 2000...2500 then "2.0-2.4 GHz"
        when 2500...3000 then "2.5-2.9 GHz"
        else "3.0+ GHz"
        end
      }
    },
    'Amount of RAM [MB]' => {
      :field => 'ramMB'
    },
    'App Version' => {
      :field => 'appVersionShort',
      :sort_by => lambda { |v| v.split('.').map(&:to_i) }
    },
    'Locale' => {
      :field => 'lang'
    }
  }

  attr_reader :months, :reports

  def initialize(feed)
    @feed = feed
    @months = feed.statistics.select('DISTINCT year, month').order('year, month').map { |r| [r.year, r.month] }

    calculate_stats
    generate_reports
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

  def generate_reports
    @reports = {}

    REPORTS.each do |report_title, options|
      property = Property.find_or_create_by(name: options[:field])

      value_title_map = options[:values]
      grouping = options[:group_by] || lambda { |title| title }
      sorting = options[:sort_by] || lambda { |title| [title.to_i, title.downcase] }

      value_ids_for_title = {}

      property.values.each do |value|
        title = grouping.call(value.name)
        processed_title = value_title_map && value_title_map[title] || title
        value_ids_for_title[processed_title] ||= []
        value_ids_for_title[processed_title] << value.id
      end

      data_lines = value_ids_for_title.keys.sort_by(&sorting).map do |title|
        counts = @months.map do |y, m|
          value_ids_for_title[title].sum { |value_id| count_for(property.id, value_id, y, m) }
        end

        [title, counts]
      end

      @reports[report_title] = data_lines.reject { |title, counts| counts.sum == 0 }
    end
  end
end
