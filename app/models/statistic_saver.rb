class StatisticSaver
  def initialize(feed)
    @feed = feed
    @properties = Property.all.includes(:options)
  end

  def save_params(params, user_agent)
    params = params.clone

    params.delete('appName')
    params.delete('controller')
    params.delete('action')
    params.delete('id')

    date = Date.today
    app_version = user_agent.split(' ').first.split('/').last
    subtype = params.delete('cpusubtype')

    if subtype && params['cputype']
      subtype = "#{params['cputype']}.#{subtype}"
    end

    params.each do |property_name, option_name|
      save_param(date, property_name, option_name)
    end

    save_param(date, 'appVersionShort', app_version)
    save_param(date, 'cpusubtype', subtype) if subtype
  end

  def save_param(date, property_name, option_name)
    property = @properties.detect { |p| p.name == property_name }

    if property.nil?
      property = Property.create!(name: property_name)
      @properties.push(property)
    end

    option = property.options.detect { |o| o.name == option_name } || property.options.create!(name: option_name)

    statistic = @feed.statistics.find_by(date: date, property: property, option: option)
    
    if statistic
      Statistic.update_counters(statistic.id, counter: 1)
    else
      @feed.statistics.create!(date: date, property: property, option: option, counter: 1)
    end
  end
end
