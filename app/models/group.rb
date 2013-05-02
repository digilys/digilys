class Group < ActiveRecord::Base
  belongs_to :parent,   class_name: "Group"
  has_many   :children, class_name: "Group", foreign_key: "parent_id", order: "name asc"

  attr_accessible :name, :parent_id

  validates :name, presence: true

  # Joins n parents up in the hierarchy.
  #
  # The parents can be queried using parent_#{i}.field syntax.
  def self.with_parents(n)
    return self if n < 1

    joins = ""
    prev = "groups"

    1.upto(n) do |i|
      current = "parent_#{i}"
      joins << " left join groups #{current} on #{prev}.parent_id = #{current}.id "
      prev = current
    end

    self.joins(joins)
  end
end
