class Property < ActiveRecord::Base
  has_many :values
  validates_presence_of :name

  PROPERTY_TITLES = {
    'Mac model': 'model',
    'CPU type': 'cputype',
    'CPU subtype': 'cpusubtype',
    'CPU bits': 'cpu64bit',
    'Number of CPUs': 'ncpu',
    'Locale': 'lang',
  }
end
