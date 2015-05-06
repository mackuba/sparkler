require 'rails_helper'

describe FeedReport do
  fixtures :feeds
  
  let(:feed) { feeds(:feed1) }
  let(:options) {{ }}
  let(:definitions) { nil }
  let(:report) { FeedReport.new(feed, options.merge(report_definitions: definitions)) }
  let(:saver) { StatisticSaver.new(feed) }

  it 'should generate reports' do
    report.reports.should be_an(Array)
    report.reports.should_not be_empty
  end

  context 'if counts should be included' do
    let(:options) {{ include_counts: true }} 
    let(:definitions) {{ 'Counts' => { field: 'a', only_counts: true }, 'Stats' => { field: 'b' } }}

    it 'should include reports that only list absolute counts' do
      report.reports.map { |r| r[:title] }.should == ['Counts', 'Stats']
    end

    it 'should include only absolute amounts in reports with only_counts flag' do
      saver.save_param(Date.today, 'a', '1')
      saver.save_param(Date.today, 'b', '2')

      report.reports[0][:series][0][:amounts].should be_an(Array)
      report.reports[0][:series][0][:normalized].should be_nil
    end

    it 'should include both absolute amounts and percentages in reports without only_counts flag' do
      saver.save_param(Date.today, 'a', '1')
      saver.save_param(Date.today, 'b', '2')

      report.reports[1][:series][0][:amounts].should be_an(Array)
      report.reports[1][:series][0][:normalized].should be_an(Array)
    end
  end

  context 'if counts should not be included' do
    let(:definitions) {{ 'Counts' => { field: 'a', only_counts: true }, 'Stats' => { field: 'b' } }}

    it 'should not include reports that only list absolute counts' do
      report.reports.map { |r| r[:title] }.should == ['Stats']
    end

    it 'should include only percentages in reports without only_counts flag' do
      saver.save_param(Date.today, 'a', '1')
      saver.save_param(Date.today, 'b', '2')

      report.reports[0][:series][0][:amounts].should be_nil
      report.reports[0][:series][0][:normalized].should be_an(Array)
    end
  end

  context "if necessary properties don't exist yet" do
    let(:definitions) {{ 'Foo' => { field: 'appSize' }}}

    it 'should create them' do
      Property.find_by_name('appSize').should be_nil

      report

      Property.find_by_name('appSize').should_not be_nil
    end
  end

  it 'should copy title from definition' do
    report = FeedReport.new(feed, report_definitions: { 'Foo' => { field: 'a' }})

    report.reports.first[:title].should == 'Foo'
  end

  it 'should copy :is_downloads flag from definition' do
    report = FeedReport.new(feed, report_definitions: { 'Foo' => { field: 'a', is_downloads: true }})

    report.reports.first[:is_downloads].should == true
  end

  it 'should copy :show_other => false flag from definition' do
    report = FeedReport.new(feed, report_definitions: { 'Foo' => { field: 'a', show_other: false }})

    report.reports.first[:show_other].should == false
  end

  it 'should calculate list of months with any statistics for the given feed' do
    saver.save_param(Date.new(2015, 1, 3), 'color', 'red')
    saver.save_param(Date.new(2015, 3, 3), 'color', 'blue')
    saver.save_param(Date.new(2015, 3, 3), 'color', 'red')
    saver.save_param(Date.new(2015, 6, 1), 'color', 'green')
    saver.save_param(Date.new(2015, 6, 3), 'version', '1.0')

    report = FeedReport.new(feed, report_definitions: { 'Foo' => { field: 'color' }})

    report.reports.first[:months].should == ['2015-01', '2015-03', '2015-06']
  end

  describe ':initial_range' do
    let(:definitions) {{ 'Foo' => { field: 'color' }}}

    context "if there's only one month of data" do
      before do
        saver.save_param(Date.new(2015, 1, 3), 'color', 'red')
      end

      it 'should be set to "month"' do
        report.reports.first[:initial_range].should == 'month'
      end
    end

    context "if there are several months of data (but less than 12)" do
      before do
        1.upto(10) { |i| saver.save_param(Date.new(2014, i, 1), 'color', 'red') }
      end

      it 'should be set to "year"' do
        report.reports.first[:initial_range].should == 'year'
      end
    end

    context "if there are more than 12 months of data" do
      before do
        1.upto(12) { |i| saver.save_param(Date.new(2014, i, 1), 'color', 'red') }
        1.upto(3) { |i| saver.save_param(Date.new(2015, i, 1), 'color', 'red') }
      end

      it 'should be set to "all"' do
        report.reports.first[:initial_range].should == 'all'
      end
    end
  end

  describe ':series' do
    subject { report.reports.first[:series] }

    let(:definitions) {{ 'Foo' => { field: 'value' }}}
    let(:options) {{ include_counts: true }} 

    it 'should calculate amounts and percentages for all months' do
      saver.save_param(Date.new(2015, 1, 3), 'value', 'iMac')
      saver.save_param(Date.new(2015, 1, 5), 'value', 'iMac')
      saver.save_param(Date.new(2015, 1, 13), 'value', 'MacBook')
      saver.save_param(Date.new(2015, 1, 13), 'value', 'iMac')
      saver.save_param(Date.new(2015, 1, 13), 'value', 'iMac')
      saver.save_param(Date.new(2015, 1, 30), 'value', 'iMac')
      saver.save_param(Date.new(2015, 2, 1), 'value', 'iMac')
      saver.save_param(Date.new(2015, 4, 3), 'value', 'MacBook')

      subject.detect { |l| l[:title] == 'iMac' }[:amounts].should == [5, 1, 0]
      subject.detect { |l| l[:title] == 'MacBook' }[:amounts].should == [1, 0, 1]

      subject.detect { |l| l[:title] == 'iMac' }[:normalized].should == [83.3, 100.0, 0.0]
      subject.detect { |l| l[:title] == 'MacBook' }[:normalized].should == [16.7, 0.0, 100.0]
    end

    it "should delete options that don't have any non-zero amounts" do
      saver.save_param(Date.today, 'value', 'red')
      saver.save_param(Date.today, 'value', 'blue')

      Property.find_by_name('value').options.create!(name: 'yellow')
      Property.find_by_name('value').options.create!(name: 'black')

      subject.map { |l| l[:title] }.should == ['blue', 'red']
    end

    context 'if grouping is defined' do
      let(:definitions) {{ 'Foo' => { field: 'value', group_by: proc { |x| x =~ /^iP/ ? 'mobile' : 'computer' }}}}

      it 'should group labels using the defined function' do
        ['iPhone', 'iPad', 'MacBook', 'iPhone', 'iMac', 'MacBook', 'iPhone', 'iPhone', 'iMac'].each do |name|
          saver.save_param(Date.today, 'value', name)
        end

        subject[0][:title].should == 'computer'
        subject[0][:amounts].should == [4]
        subject[0][:normalized].should == [44.4]
        subject[1][:title].should == 'mobile'
        subject[1][:amounts].should == [5]
        subject[1][:normalized].should == [55.6]
      end
    end

    describe 'sorting' do
      it 'should sort labels alphabetically' do
        saver.save_param(Date.today, 'value', 'red')
        saver.save_param(Date.today, 'value', 'blue')
        saver.save_param(Date.today, 'value', 'green')
        saver.save_param(Date.today, 'value', 'FFE0E0')

        subject.map { |l| l[:title] }.should == ['blue', 'FFE0E0', 'green', 'red']
      end

      it 'should try to sort labels numerically if possible' do
        saver.save_param(Date.today, 'value', '1 MB')
        saver.save_param(Date.today, 'value', '50 MB')
        saver.save_param(Date.today, 'value', '10 MB')
        saver.save_param(Date.today, 'value', '2 MB')

        subject.map { |l| l[:title] }.should == ['1 MB', '2 MB', '10 MB', '50 MB']
      end

      context 'if a custom sorter is defined' do
        let(:definitions) {{ 'Foo' => { field: 'value', sort_by: lambda { |x| x.length }}}}

        it 'should sort the values using the defined function' do
          saver.save_param(Date.today, 'value', 'tiny')
          saver.save_param(Date.today, 'value', 'small')
          saver.save_param(Date.today, 'value', 'average')
          saver.save_param(Date.today, 'value', 'big')

          subject.map { |l| l[:title] }.should == ['big', 'tiny', 'small', 'average']
        end
      end

      context 'if grouping is also defined' do
        let(:definitions) {{ 'Foo' => {
          field: 'value',
          sort_by: lambda { |x| x.reverse },
          group_by: lambda { |x| x[0..1].upcase }
        }}}

        it 'should do the grouping before the sorting' do
          saver.save_param(Date.today, 'value', 'france')
          saver.save_param(Date.today, 'value', 'portugal')
          saver.save_param(Date.today, 'value', 'norway')
          saver.save_param(Date.today, 'value', 'hungary')
          saver.save_param(Date.today, 'value', 'poland')

          subject.map { |l| l[:title] }.should == ['NO', 'PO', 'FR', 'HU']
        end
      end

      context 'if converting proc is also defined' do
        let(:definitions) {{ 'Foo' => {
          field: 'value',
          sort_by: lambda { |x| x[1..-1] },
          options: lambda { |x| x.reverse }
        }}}

        it 'should do the converting before the sorting' do
          saver.save_param(Date.today, 'value', 'france')
          saver.save_param(Date.today, 'value', 'norway')
          saver.save_param(Date.today, 'value', 'poland')

          subject.map { |l| l[:title] }.should == ['yawron', 'ecnarf', 'dnalop']
        end
      end
    end

    describe 'converting labels' do
      context 'if a proc is given' do
        let(:definitions) {{ 'Foo' => { field: 'value', options: lambda { |x| x.upcase }}}}

        it 'should pass the labels through the proc' do
          saver.save_param(Date.today, 'value', 'foo')
          saver.save_param(Date.today, 'value', 'bar')

          subject.map { |l| l[:title] }.should == ['BAR', 'FOO']
        end
      end

      context 'if a hash is given' do
        let(:definitions) {{ 'Foo' => { field: 'value', options: { 'foo' => 'a', 'bar' => 'b' }}}}

        it 'should use the hash to map labels to proper titles' do
          saver.save_param(Date.today, 'value', 'foo')
          saver.save_param(Date.today, 'value', 'bar')

          subject.map { |l| l[:title] }.should == ['a', 'b']
        end

        it "should use original labels if they don't appear in the hash" do
          saver.save_param(Date.today, 'value', 'foo')
          saver.save_param(Date.today, 'value', 'bar')
          saver.save_param(Date.today, 'value', 'baz')

          subject.map { |l| l[:title] }.should == ['a', 'b', 'baz']
        end
      end

      context 'if grouping is also defined' do
        let(:definitions) {{ 'Foo' => {
          field: 'value',
          options: lambda { |x| x.gsub(/Book(\w)/, 'Book \1') },
          group_by: lambda { |x| x[/^[a-z]+/i] }
        }}}

        it 'should do the grouping before the converting' do
          saver.save_param(Date.today, 'value', 'MacBookPro1,2')
          saver.save_param(Date.today, 'value', 'MacBookAir1,3')
          saver.save_param(Date.today, 'value', 'MacBookPro5,6')

          subject.map { |l| l[:title] }.should == ['MacBook Air', 'MacBook Pro']
        end
      end
    end

    context 'if threshold is set' do
      let(:definitions) {{ 'Foo' => {
        field: 'color',
        threshold: 20.0
      }}}

      it 'should group datasets that never get above <threshold> percent into an "Other" dataset' do
        saver.save_param(Date.new(2015, 1, 1), 'color', 'red')
        saver.save_param(Date.new(2015, 1, 2), 'color', 'blue')
        saver.save_param(Date.new(2015, 1, 3), 'color', 'green')

        saver.save_param(Date.new(2015, 2, 1), 'color', 'yellow')
        saver.save_param(Date.new(2015, 2, 1), 'color', 'red')

        saver.save_param(Date.new(2015, 3, 1), 'color', 'red')
        saver.save_param(Date.new(2015, 3, 2), 'color', 'blue')
        saver.save_param(Date.new(2015, 3, 2), 'color', 'red')
        saver.save_param(Date.new(2015, 3, 3), 'color', 'red')
        saver.save_param(Date.new(2015, 3, 4), 'color', 'green')
        saver.save_param(Date.new(2015, 3, 5), 'color', 'black')
        saver.save_param(Date.new(2015, 3, 10), 'color', 'white')

        subject.map { |l| l[:title] }.should == ['blue', 'green', 'red', 'yellow', 'Other']

        subject.last[:amounts].should == [0, 0, 2]
        subject.last[:normalized].should == [0, 0, 28.6]
        subject.last[:is_other].should == true
      end
    end
  end
end
