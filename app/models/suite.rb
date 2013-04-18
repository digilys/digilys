class Suite < ActiveRecord::Base
  has_many :evaluations

  attr_accessible :name
  validates :name, presence: true
end
