class Suite < ActiveRecord::Base
  has_many :evaluations
  has_many :results,  through: :evaluations
  has_many :students, through: :results, order: "name asc", uniq: true

  attr_accessible :name
  validates :name, presence: true
end
