class Instance < ActiveRecord::Base
  resourcify

  has_many :students
  has_many :groups

  attr_accessible :name

  validates :name, presence: true
end
