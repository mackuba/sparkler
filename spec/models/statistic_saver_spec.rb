require 'rails_helper'

describe StatisticSaver do
  let(:feed) { Feed.create(name: 'feed', title: 'Feed', url: 'http://onet.pl') }
  let(:date) { Date.today }
  subject { StatisticSaver.new(feed) }

  describe '#save_param' do
    context "if a given property doesn't exist" do
      it 'should create it' do
        Property.find_by_name('foobars').should be_nil

        subject.save_param(date, 'foobars', '1000')

        Property.find_by_name('foobars').should_not be_nil
      end
    end

    context "if a given option doesn't exist" do
      it 'should create it' do
        Option.find_by(name: '1000').should be_nil

        subject.save_param(date, 'foobars', '1000')

        property = Property.find_by_name('foobars')
        property.options.find_by(name: '1000').should_not be_nil
      end
    end

    context "if a statistic for a given option doesn't exist yet" do
      it 'should create it with counter set to 1' do
        subject.save_param(date, 'foobars', '1000')

        property = Property.find_by_name('foobars')
        option = property.options.find_by_name('1000')

        statistic = Statistic.find_by(property: property, option: option, date: date)
        statistic.should_not be_nil
        statistic.counter.should == 1
      end
    end

    context 'if a statistic for a given option already exists' do
      it 'should not create it again' do
        subject.save_param(date, 'foobars', '1000')

        expect { subject.save_param(date, 'foobars', '1000') }.not_to change(Statistic, :count)
      end

      it 'should increase its counter' do
        subject.save_param(date, 'foobars', '1000')
        subject.save_param(date, 'foobars', '1000')

        property = Property.find_by_name('foobars')
        option = property.options.find_by_name('1000')

        statistic = Statistic.find_by(property: property, option: option, date: date)
        statistic.counter.should == 2
      end
    end
  end

  describe '#save_params' do
    let(:user_agent) { 'Sparkler/1.0 foo/5' }

    it 'should create statistics based on the params' do
      params = { 'color' => 'green', 'size' => 'XL' }

      subject.save_params(params, user_agent)

      statistics = feed.statistics.order('id')

      color = statistics.detect { |s| s.property.name == 'color' }
      color.should_not be_nil
      color.option.name.should == 'green'
      color.counter.should == 1

      size = statistics.detect { |s| s.property.name == 'size' }
      size.should_not be_nil
      size.option.name.should == 'XL'
      size.counter.should == 1
    end

    it "should save statistics with today's date" do
      params = { 'color' => 'green' }
      subject.save_params(params, user_agent)

      feed.statistics.each { |s| s.date.should == Date.today }
    end

    it 'should ignore parameters added internally by Rails' do
      params = { 'controller' => 'feeds', 'action' => 'show', 'id' => '123', 'color' => 'green' }
      subject.save_params(params, user_agent)

      feed.statistics.detect { |s| s.property.name == 'controller' }.should be_nil
      feed.statistics.detect { |s| s.property.name == 'action' }.should be_nil
      feed.statistics.detect { |s| s.property.name == 'id' }.should be_nil
    end

    it 'should ignore appName parameter' do
      params = { 'appName' => 'Sparkler', 'version' => '2.0' }
      subject.save_params(params, user_agent)

      feed.statistics.detect { |s| s.property.name == 'appName' }.should be_nil
    end

    it 'should extract version number from user agent and save it as appVersionShort' do
      subject.save_params({}, 'app/10.5 Sparkle/0.9')

      version = feed.statistics.detect { |s| s.property.name == 'appVersionShort' }
      version.should_not be_nil
      version.option.name.should == '10.5'
    end

    context 'if there is a cpusubtype field' do
      context 'if there is also a cputype field' do
        it 'should prefix the cpusubtype option name with the cpu type' do
          subject.save_params({ 'cputype' => '5', 'cpusubtype' => '15' }, user_agent)

          subtype = feed.statistics.detect { |s| s.property.name == 'cpusubtype' }
          subtype.should_not be_nil
          subtype.option.name.should == '5.15'
        end
      end

      context 'if there is no cputype field' do
        it 'should not prefix the cpusubtype option' do
          subject.save_params({ 'cpusubtype' => '15' }, user_agent)

          subtype = feed.statistics.detect { |s| s.property.name == 'cpusubtype' }
          subtype.should_not be_nil
          subtype.option.name.should == '15'
        end
      end
    end

    context 'if there is no cpusubtype field' do
      it 'should not save it' do
        subject.save_params({ 'cputype' => '5' }, user_agent)

        subtype = feed.statistics.detect { |s| s.property.name == 'cpusubtype' }
        subtype.should be_nil
      end
    end

    it 'should not modify the original hash' do
      params = { 'appName' => 'Sparkler', 'version' => '1.0' }

      subject.save_params(params, user_agent)

      params.keys.should == ['appName', 'version']
    end
  end
end
