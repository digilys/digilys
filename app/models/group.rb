class Group < ActiveRecord::Base
  belongs_to :instance
  belongs_to :parent,   class_name: "Group"

  has_many   :children,
    class_name:  "Group",
    foreign_key: "parent_id",
    order:       "name asc",
    dependent:   :nullify

  has_and_belongs_to_many :students
  has_and_belongs_to_many :activities
  has_and_belongs_to_many :users,    order: "users.name asc"

  has_many :participants, dependent: :nullify
  has_many :suites,       through:   :students

  attr_accessible :name,
    :parent_id,
    :imported,
    :instance,
    :instance_id

  validates :name,     presence: true
  validates :instance, presence: true

  validate :must_belong_to_parent_instance

  after_update  :touch_suites
  after_destroy :touch_suites


  # Adds students to this group and all the parents
  def add_students(students)
    return if students.blank?

    students = Student.find(students.split(/\s*,\s*/)) if students.is_a? String

    students = [*students].reject { |s| s.instance_id != self.instance_id }

    return if students.blank?

    group = self

    until group.nil?
      students.each do |student|
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

  def add_users(users)
    return if users.blank?
    users = User.find(users.split(/\s*,\s*/))
    users.each { |user| self.users << user unless self.users.include?(user) }
  end

  def remove_users(users)
    return if users.blank?
    users = User.find(users.split(/\s*,\s*/))
    users.each { |user| self.users.delete(user) }
  end


  # Joins n parents up in the hierarchy.
  #
  # The parents can be queried using parent_#{i}.field syntax.
  def self.with_parents(n, ordered = false)
    return self if n < 1

    joins = ""
    prev = "groups"

    1.upto(n) do |i|
      current = "parent_#{i}"
      joins << " left join groups #{current} on #{prev}.parent_id = #{current}.id "
      prev = current
    end

    result = self.joins(joins)

    if ordered
      result = result.order(["groups.name", *1.upto(n).collect { |i| "parent_#{i}.name" }].join(","))
    end

    return result
  end

  # Adds a condition removing all groups with a parent,
  # thus giving the top level groups
  def self.top_level
    where(parent_id: nil)
  end
  

  private

  def touch_suites
    # See ActiveRecord#current_time_from_proper_timezone
    timestamp = self.class.default_timezone == :utc ? Time.now.utc : Time.now
    self.suites.update_all(updated_at: timestamp)
  end

  def remove_students_from_all(students, groups)
    groups.each do |group|
      group.students.delete(students)
      remove_students_from_all(students, group.children)
    end
  end


  def must_belong_to_parent_instance
    if self.parent && self.parent.instance_id != self.instance_id
      errors.add(:instance, :invalid_instance)
    end
  end
end
