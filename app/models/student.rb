class Student < ActiveRecord::Base
  has_many :participants, dependent: :destroy
  has_many :suites,       through: :participants
  has_many :results,      dependent: :destroy
  has_many :evaluations,  through: :results

  has_and_belongs_to_many :groups

  attr_accessible :name
  validates :name, presence: true

  # Add this user to all of the groups, and all of the group's parents
  def add_to_groups(groups)
    return if groups.blank?

    groups = Group.find(groups.split(/\s*,\s*/)) if groups.is_a? String

    [*groups].each do |group|
      group.add_students(self)
    end
  end

  # Removes this user to all of the groups, and all of the group's parents
  def remove_from_groups(groups)
    return if groups.blank?

    [*groups].each do |g|
      group = g.is_a?(Group) ? g : Group.find(g)
      group.remove_students(self)
    end
  end
end
