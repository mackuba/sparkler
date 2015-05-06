# encoding: utf-8

FeedReport.report_types = {
  'Total feed downloads' => {
    :field => 'osVersion',
    :group_by => lambda { |v| "Downloads" },
    :only_counts => true,
    :is_downloads => true
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
    :show_other => false,
    :options => {
      'iMac12,1' => 'iMac 21" (2011)',
      'iMac12,2' => 'iMac 27" (2011)',
      'iMac13,1' => 'iMac 21" (2012)',
      'iMac13,2' => 'iMac 27" (2012)',
      'iMac14,1' => 'iMac 21" (2013)',
      'iMac14,2' => 'iMac 27" (2013)',
      'iMac14,4' => 'iMac 21" (2014)',
      'iMac15,1' => 'Retina iMac 27" (2014)',

      'MacBookAir6,1' => 'MBA 11" (2013-14)',
      'MacBookAir6,2' => 'MBA 13" (2013-14)',
      'MacBookAir7,1' => 'MBA 11" (2015)',
      'MacBookAir7,2' => 'MBA 13" (2015)',

      'MacBookPro6,1' => 'MBP 17" (2010)',
      'MacBookPro6,2' => 'MBP 15" (2010)',
      'MacBookPro7,1' => 'MBP 13" (2010)',
      'MacBookPro8,1' => 'MBP 13" (2011)',
      'MacBookPro8,2' => 'MBP 15" (2011)',
      'MacBookPro8,3' => 'MBP 17" (2011)',
      'MacBookPro9,1' => 'MBP 15" (2012)',
      'MacBookPro9,2' => 'MBP 13" (2012)',
      'MacBookPro10,1' => 'Retina MBP 15" (2012-13)',
      'MacBookPro10,2' => 'Retina MBP 13" (2012-13)',
      'MacBookPro11,1' => 'Retina MBP 13" (2013-14)',
      'MacBookPro11,2' => 'Retina MBP 15" (2013-14)',
      'MacBookPro11,3' => 'Retina MBP 15" (2013-14)',
      'MacBookPro12,1' => 'Retina MBP 13" (2015)',
    }
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
      '18.9' => 'PowerPC 750',
      '18.10' => 'PowerPC 7400',
      '18.11' => 'PowerPC 7450',
      '18.100' => 'PowerPC 970'
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
      ghz = (v.to_i / 500 * 5).to_f / 10
      "#{ghz} – #{ghz + 0.4} GHz"
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
