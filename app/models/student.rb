class Student < ActiveRecord::Base
  has_many :results

  attr_accessible :name
  validates :name, presence: true
end
