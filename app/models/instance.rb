class Instance < ActiveRecord::Base
  resourcify

  attr_accessible :name

  validates :name, presence: true
end
