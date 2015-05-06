# encoding: utf-8

class FeedReport
  YM_FORMAT = "DATE_FORMAT(date, '%Y-%m')"

  attr_reader :reports
  cattr_accessor :report_types

  def initialize(feed, options = {})
    @feed = feed
    @include_counts = options[:include_counts]
    @properties = Property.all.includes(:options)
    @report_types = options[:report_types] || self.class.report_types

    @months = feed.statistics.select("DISTINCT #{YM_FORMAT} AS ym").order('ym').map(&:ym)

    calculate_stats
    generate_reports
  end

  def calculate_stats
    @stats = {}

    grouped_statistics = @feed.statistics
      .select("#{YM_FORMAT} AS ym, property_id, option_id, SUM(counter) AS total_for_month")
      .group("ym, property_id, option_id")

    grouped_statistics.each do |stat|
      property_stats = @stats[stat.property_id] ||= {}
      option_stats = property_stats[stat.option_id] ||= {}
      option_stats[stat.ym] = stat.total_for_month
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
    @reports = []

    @report_types.each do |report_title, options|
      next if options[:only_counts] && !@include_counts

      property = @properties.detect { |p| p.name == options[:field] } || Property.create!(name: options[:field])

      option_converter = case options[:options]
        when Proc then options[:options]
        when Hash then lambda { |title| options[:options][title] || title }
        else lambda { |title| title }
      end

      grouping = options[:group_by] || lambda { |title| title }
      sorting = options[:sort_by] || lambda { |title| [title.to_i, title.downcase] }

      option_ids_for_title = {}

      property.options.each do |option|
        title = option_converter.call(grouping.call(option.name)).to_s
        option_ids_for_title[title] ||= []
        option_ids_for_title[title] << option.id
      end

      data_lines = option_ids_for_title.keys.sort_by(&sorting).map do |title|
        option_ids = option_ids_for_title[title]

        amounts = []
        normalized_amounts = []

        @months.each do |ym|
          amount = option_ids.sum { |option_id| count_for(property.id, option_id, ym) }
          total = sum_for(property.id, ym)
          normalized = (total > 0) ? (amount * 100.0 / total).round(1) : 0

          amounts.push(amount)
          normalized_amounts.push(normalized)
        end

        { title: title, amounts: amounts, normalized: normalized_amounts }
      end

      data_lines.delete_if { |d| d[:amounts].sum == 0 }

      if options[:threshold]
        other = []

        data_lines.clone.each do |dataset|
          if dataset[:normalized].max < options[:threshold]
            data_lines.delete(dataset)
            other.push(dataset)
          end
        end

        amounts = []
        normalized_amounts = []

        @months.each_with_index do |ym, i|
          amount = other.sum { |dataset| dataset[:amounts][i] }
          total = sum_for(property.id, ym)
          normalized = (total > 0) ? (amount * 100.0 / total).round(1) : 0

          amounts.push(amount)
          normalized_amounts.push(normalized)
        end

        other_dataset = {
          title: "Other",
          is_other: true,
          amounts: amounts,
          normalized: normalized_amounts
        }
      
        data_lines.push(other_dataset)
      end

      if options[:only_counts]
        data_lines.each { |dataset| dataset.delete(:normalized) }
      elsif !@include_counts
        data_lines.each { |dataset| dataset.delete(:amounts) }
      end

      report = { title: report_title, months: @months, series: data_lines }

      report[:is_downloads] = true if options[:is_downloads]
      report[:show_other] = false if options[:show_other] == false
      report[:initial_range] = case @months.length
        when 1 then 'month'
        when 2..12 then 'year'
        else 'all'
      end

      @reports.push(report)
    end
  end
end
