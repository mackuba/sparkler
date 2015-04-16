class FeedReport
  REPORTS = {
    'Total feed downloads' => {
      :field => 'osVersion',
      :group_by => lambda { |v| "Downloads" },
      :only_counts => true
    },
    'OS X Version' => {
      :field => 'osVersion',
      :group_by => lambda { |v| v.split('.').first(2).join('.') },
      :sort_by => lambda { |v| v.split('.').map(&:to_i) }
    },
    'Mac Class' => {
      :field => 'model',
      :group_by => lambda { |v| v[/^[[:alpha:]]+/] },
      :options => {
        'MacBookAir' => 'MacBook Air',
        'MacBookPro' => 'MacBook Pro',
        'Macmini' => 'Mac Mini',
        'MacPro' => 'Mac Pro'
      }
    },
    'Mac Model' => {
      :field => 'model',
      :threshold => 7.5,
    },
    'Number of CPU Cores' => {
      :field => 'ncpu'
    },
    'CPU Type' => {
      :field => 'cputype',
      :options => {
        '7' => 'Intel',
        '18' => 'PowerPC'
      }
    },
    'CPU Subtype' => {
      :field => 'cpusubtype',
      :options => {
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
      :options => {
        '0' => '32-bit',
        '1' => '64-bit'
      }
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
      :threshold => 2.5,
      :options => lambda { |v| "#{v.to_i / 1024} GB" }
    },
    'App Version' => {
      :field => 'appVersionShort',
      :sort_by => lambda { |v| v.split('.').map(&:to_i) }
    },
    'System Locale' => {
      :field => 'lang',
      :threshold => 2.5
    }
  }

  def initialize(feed, options = {})
    @feed = feed
    @include_counts = options[:include_counts]

    @months = feed.statistics.select('DISTINCT year, month').order('year, month').map { |r| [r.year, r.month] }

    calculate_stats
    generate_reports
  end

  def calculate_stats
    @stats = {}

    @feed.statistics.each do |stat|
      ym = [stat.year, stat.month]
      property_stats = @stats[stat.property_id] ||= {}
      option_stats = property_stats[stat.option_id] ||= {}
      option_stats[ym] = stat.counter
    end

    @sums = {}
    @stats.each do |property_id, property_stats|
      property_sums = @sums[property_id] ||= {}
      property_stats.each do |option_id, option_stats|
        option_stats.each do |ym, count|
          property_sums[ym] ||= 0
          property_sums[ym] += count
        end
      end
    end
  end

  def sum_for(property_id, ym)
    @sums[property_id] && @sums[property_id][ym] || 0
  end

  def count_for(property_id, option_id, ym)
    property_stats = @stats[property_id] || {}
    option_stats = property_stats[option_id] || {}
    option_stats[ym] || 0
  end

  def generate_reports
    @reports = {}

    REPORTS.each do |report_title, options|
      next if options[:only_counts] && !@include_counts

      property = Property.find_or_create_by(name: options[:field])

      option_converter = case options[:options]
        when Proc then options[:options]
        when Hash then lambda { |title| options[:options][title] || title }
        else lambda { |title| title }
      end

      grouping = options[:group_by] || lambda { |title| title }
      sorting = options[:sort_by] || lambda { |title| [title.to_i, title.downcase] }

      option_ids_for_title = {}

      property.options.each do |option|
        title = option_converter.call(grouping.call(option.name))
        option_ids_for_title[title] ||= []
        option_ids_for_title[title] << option.id
      end

      data_lines = option_ids_for_title.keys.sort_by(&sorting).map do |title|
        option_ids = option_ids_for_title[title]

        counts = []
        normalized_counts = []

        @months.each do |ym|
          count = option_ids.sum { |option_id| count_for(property.id, option_id, ym) }
          total = sum_for(property.id, ym)
          normalized = (total > 0) ? (count * 1000 / total / 10.0) : 0

          counts.push(count)
          normalized_counts.push(normalized)
        end

        [title, counts, normalized_counts]
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

      if options[:only_counts]
        data_lines.each { |dataset| dataset.delete_at(2) }
      elsif !@include_counts
        data_lines.each { |dataset| dataset.delete_at(1) }
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
