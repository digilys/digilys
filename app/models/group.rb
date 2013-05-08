class Group < ActiveRecord::Base
  belongs_to :parent,   class_name: "Group"
  has_many   :children, class_name: "Group", foreign_key: "parent_id", order: "name asc"

  has_and_belongs_to_many :students, order: "students.name asc"

  attr_accessible :name, :parent_id

  validates :name, presence: true


  # Adds students to this group and all the parents
  def add_students(students)
    return if students.blank?

    students = Student.find(students.split(/\s*,\s*/)) if students.is_a? String

    group = self

    until group.nil?
      [*students].each do |student|
        group.students << student unless group.students.include?(student)
      end
      group = group.parent
    end
  end

  # Removes students from this group and all the parents
  def remove_students(students)
    return if students.blank?

    students = Array(students).collect { |s| s.is_a?(Student) ? s : Student.find(s) }

    remove_students_from_all(students, self.children)

    group = self

    until group.nil?
      group.students.delete(students)
      group = group.parent
    end
  end


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
  
  private

  def remove_students_from_all(students, groups)
    groups.each do |group|
      group.students.delete(students)
      remove_students_from_all(students, group.children)
    end
  end
end