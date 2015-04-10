class FeedReport
  REPORTS = {
    'Total downloads' => {
      :field => 'osVersion',
      :group_by => lambda { |v| "Downloads" }
    },
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
      :field => 'model',
      :threshold => 10.0
    },
    'CPU Type' => {
      :field => 'cputype',
      :values => {
        '7' => 'Intel',
        '18' => 'PowerPC'
      }
    },
    'CPU Subtype' => {
      :field => 'cpusubtype',
      :values => {
        '7.4' => 'X86_ARCH1',
        '7.8' => 'X86_64_H (Haswell)',
        '18.9' => 'POWERPC_750',
        '18.10' => 'POWERPC_7400',
        '18.11' => 'POWERPC_7450',
        '18.100' => 'POWERPC_970'
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
    'Amount of RAM' => {
      :field => 'ramMB',
      :threshold => 2,
      :values => lambda { |v| "#{v.to_i / 1024} GB" }
    },
    'App Version' => {
      :field => 'appVersionShort',
      :sort_by => lambda { |v| v.split('.').map(&:to_i) }
    },
    'Locale' => {
      :field => 'lang',
      :threshold => 5
    }
  }

  def initialize(feed)
    @feed = feed
    @months = feed.statistics.select('DISTINCT year, month').order('year, month').map { |r| [r.year, r.month] }

    calculate_stats
    generate_reports
  end

  def calculate_stats
    @stats = {}

    @feed.statistics.each do |stat|
      ym = [stat.year, stat.month]
      property_stats = @stats[stat.property_id] ||= {}
      value_stats = property_stats[stat.value_id] ||= {}
      value_stats[ym] = stat.counter
    end

    @sums = {}
    @stats.each do |property_id, property_stats|
      property_sums = @sums[property_id] ||= {}
      property_stats.each do |value_id, value_stats|
        value_stats.each do |ym, count|
          property_sums[ym] ||= 0
          property_sums[ym] += count
        end
      end
    end
  end

  def sum_for(property_id, ym)
    @sums[property_id] && @sums[property_id][ym] || 0
  end

  def count_for(property_id, value_id, ym)
    property_stats = @stats[property_id] || {}
    value_stats = property_stats[value_id] || {}
    value_stats[ym] || 0
  end

  def generate_reports
    @reports = {}

    REPORTS.each do |report_title, options|
      property = Property.find_or_create_by(name: options[:field])

      value_converter = case options[:values]
        when Proc then options[:values]
        when Hash then lambda { |title| options[:values][title] || title }
        else lambda { |title| title }
      end

      grouping = options[:group_by] || lambda { |title| title }
      sorting = options[:sort_by] || lambda { |title| [title.to_i, title.downcase] }

      value_ids_for_title = {}

      property.values.each do |value|
        title = value_converter.call(grouping.call(value.name))
        value_ids_for_title[title] ||= []
        value_ids_for_title[title] << value.id
      end

      data_lines = value_ids_for_title.keys.sort_by(&sorting).map do |title|
        value_ids = value_ids_for_title[title]

        counts = @months.map do |ym|
          count = value_ids.sum { |value_id| count_for(property.id, value_id, ym) }
          total = sum_for(property.id, ym)
          [count, total > 0 ? count * 1000 / total / 10.0 : 0]
        end

        [title] + counts.transpose
      end

      data_lines.delete_if { |title, counts, normalized| counts.sum == 0 }

      if options[:threshold]
        other = []

        data_lines.clone.each do |dataset|
          title, counts, normalized = dataset
          if normalized.max < options[:threshold]
            data_lines.delete(dataset)
            other.push(dataset)
          end
        end
        
        other_dataset = [
          "Other",
          other.reduce([0] * @months.length) { |sum, dataset| sum.each_with_index { |x, i| sum[i] += dataset[1][i] }; sum },
          other.reduce([0] * @months.length) { |sum, dataset| sum.each_with_index { |x, i| sum[i] += dataset[2][i] }; sum }
        ]
        
        data_lines.push(other_dataset)
      end

      @reports[report_title] = data_lines
    end
  end

  def reports
    @reports.keys
  end

  def data_for_report(title)
    {
      months: @months,
      series: @reports[title]
    }
  end
end
