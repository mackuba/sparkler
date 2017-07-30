class FeedReport
  attr_reader :reports
  cattr_accessor :report_types

  def initialize(feed, options = {})
    @include_counts = options[:include_counts]
    @report_types = options[:report_types] || self.class.report_types

    @feed = feed
    @months = generate_months(feed.statistics)
    @properties = Property.all.includes(:options).to_a

    calculate_counts
    calculate_sums
    generate_reports
  end

  def generate_months(collection)
    return [] if collection.count == 0

    date = collection.order('date').first.date
    end_date = collection.order('date').last.date
    months = []

    loop do
      break if date > end_date
      months << date.strftime("%Y-%m")
      date = date.next_month
    end

    months
  end

  def calculate_counts
    @counts = {}

    grouped_statistics = @feed.statistics
      .select("DATE_FORMAT(date, '%Y-%m') AS ym, property_id, option_id, SUM(counter) AS total_for_month")
      .group("ym, property_id, option_id")

    grouped_statistics.each do |stat|
      property_stats = @counts[stat.property_id] ||= {}
      option_stats = property_stats[stat.option_id] ||= {}
      option_stats[stat.ym] = stat.total_for_month
    end
  end

  def calculate_sums
    @sums = {}

    @counts.each do |property_id, property_stats|
      property_sums = @sums[property_id] ||= {}
      property_stats.each do |option_id, option_stats|
        option_stats.each do |ym, count|
          property_sums[ym] ||= 0
          property_sums[ym] += count
        end
      end
    end
  end

  def count_for(property_id, option_id, ym)
    property_stats = @counts[property_id] || {}
    option_stats = property_stats[option_id] || {}
    option_stats[ym] || 0
  end

  def sum_for(property_id, ym)
    @sums[property_id] && @sums[property_id][ym] || 0
  end

  def generate_reports
    @reports = []

    @report_types.each do |report_title, options|
      next if options[:only_counts] && !@include_counts

      report = generate_report(report_title, options)
      @reports.push(report)
    end
  end

  def generate_report(report_title, options)
    property = @properties.detect { |p| p.name == options[:field] }

    if property.nil?
      property = Property.create!(name: options[:field])
      @properties.push(property)
    end

    converting_proc = case options[:options]
      when Proc then options[:options]
      when Hash then lambda { |title| options[:options][title] || title }
      else lambda { |title| title }
    end

    grouping_proc = options[:group_by] || lambda { |title| title }
    sorting_proc = options[:sort_by] || lambda { |title| [title.to_i, title.downcase] }

    option_map = processed_options(property.options, grouping_proc, converting_proc, sorting_proc)

    data_lines = option_map.map do |title, options|
      amounts, normalized = calculate_dataset(property) do |ym, i|
        options.sum { |o| count_for(property.id, o.id, ym) }
      end

      { title: title, amounts: amounts, normalized: normalized }
    end

    data_lines.delete_if { |d| d[:amounts].sum == 0 }

    if options[:threshold]
      data_lines = extract_other_dataset(data_lines, property, options[:threshold])
    end

    if options[:only_counts]
      data_lines.each { |dataset| dataset.delete(:normalized) }
    else
      if !@include_counts
        data_lines.each { |dataset| dataset.delete(:amounts) }
      end
    end

    report = {
      title: report_title,
      months: @months,
      series: data_lines,
      initial_range: case @months.length
        when 1 then 'month'
        when 2..12 then 'year'
        else 'all'
      end
    }

    report[:is_downloads] = options[:is_downloads] if options.has_key?(:is_downloads)
    report[:show_other] = options[:show_other] if options.has_key?(:show_other)

    report
  end

  def processed_options(options, grouping_proc, converting_proc, sorting_proc)
    grouped_options = {}

    options.each do |option|
      title = converting_proc.call(grouping_proc.call(option.name).to_s).to_s
      grouped_options[title] ||= []
      grouped_options[title] << option
    end

    sorted_options = {}

    grouped_options.keys.sort_by(&sorting_proc).each do |title|
      sorted_options[title] = grouped_options[title]
    end
    
    sorted_options
  end

  def calculate_dataset(property, &amount_proc)
    amounts = []
    normalized_amounts = []

    @months.each_with_index do |ym, index|
      amount = amount_proc.call(ym, index)
      total = sum_for(property.id, ym)
      normalized = (total > 0) ? (amount * 100.0 / total).round(1) : 0

      amounts.push(amount)
      normalized_amounts.push(normalized)
    end

    [amounts, normalized_amounts]
  end

  def extract_other_dataset(data_lines, property, threshold)
    other = data_lines.select { |dataset| dataset[:normalized].max < threshold }

    amounts, normalized = calculate_dataset(property) { |ym, i| other.sum { |dataset| dataset[:amounts][i] }}

    other_dataset = {
      title: 'Other',
      is_other: true,
      amounts: amounts,
      normalized: normalized
    }

    data_lines - other + [other_dataset]
  end
end
