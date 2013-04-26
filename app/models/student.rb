class Student < ActiveRecord::Base
  has_many :participants
  has_many :suites,      through: :participants
  has_many :results
  has_many :evaluations, through: :results

  attr_accessible :name
  validates :name, presence: true
end
