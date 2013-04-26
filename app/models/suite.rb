class Suite < ActiveRecord::Base
  has_many :participants
  has_many :students, through: :participants, order: "name asc"
  has_many :evaluations
  has_many :results,  through: :evaluations

  attr_accessible :name
  validates :name, presence: true
end
