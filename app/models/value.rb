class Value < ActiveRecord::Base
  belongs_to :property
  validates_presence_of :name

  HUMAN_READABLE_NAMES = {
    'cputype' => {
      '7' => 'Intel',
      '18' => 'PowerPC'
    },
    'cpu64bit' => {
      '0' => '32-bit',
      '1' => '64-bit'
    }
  }
end
