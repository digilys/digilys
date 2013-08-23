# Link model for students participating in suites
class Participant < ActiveRecord::Base
  belongs_to :student
  belongs_to :suite
  belongs_to :group

  has_and_belongs_to_many :evaluations

  attr_accessible :student_id,
    :suite_id,
    :group_id

  validates :student, presence:   true
  validates :suite,   presence:   true
  validates :student_id, uniqueness: { scope: :suite_id }

  after_create  :add_group_users_to_suite
  after_create  :update_evaluation_statuses!
  after_destroy :update_evaluation_statuses!

  def name
    self.student.name
  end
  
  def group_names
    self.student.groups.collect(&:name).join(", ")
  end

  def self.with_gender(gender)
    includes(:student).where("students.gender" => gender.to_s)
  end

  def self.with_student_ids(ids)
    where(student_id: ids)
  end

  def self.with_implicit_group_ids(ids)
    where([ "student_id in (select student_id from groups_students where group_id in (?))", ids])
  end


  private

  def add_group_users_to_suite
    if self.group && self.suite
      self.group.users.each { |u| u.add_role :suite_contributor, self.suite }
    end
  end

  def update_evaluation_statuses!
    self.suite.update_evaluation_statuses! if self.suite
  end
end
