class Student < ActiveRecord::Base
  has_many :participants, dependent: :destroy
  has_many :suites,       through: :participants
  has_many :results,      dependent: :destroy
  has_many :evaluations,  through: :results

  has_and_belongs_to_many :groups

  attr_accessible :name
  validates :name, presence: true
end
