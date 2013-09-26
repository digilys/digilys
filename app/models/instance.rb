class Instance < ActiveRecord::Base
  resourcify

  has_many :students

  attr_accessible :name

  validates :name, presence: true
end
