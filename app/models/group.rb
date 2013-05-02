class Group < ActiveRecord::Base
  belongs_to :parent,   class_name: "Group"
  has_many   :children, class_name: "Group", foreign_key: "parent_id"

  attr_accessible :name, :parent_id

  validates :name, presence: true
end
