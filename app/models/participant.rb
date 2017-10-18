# Link model for students participating in suites
class Participant < ActiveRecord::Base

  has_paper_trail meta: { suite_id: ->(s) { s.suite_id } }

  belongs_to :student
  belongs_to :suite
  belongs_to :group

  has_and_belongs_to_many :evaluations

  attr_accessible :student_id,
    :suite_id,
    :group_id

  validates :student,    presence:   true
  validates :suite,      presence:   true
  validates :student_id, uniqueness: { scope: :suite_id }

  validate :student_and_suite_must_have_the_same_instance

  after_create  :add_absent_results_for_passed_evaluations
  after_create  :add_group_users_to_suite
  after_create  :update_evaluation_statuses!
  after_destroy :update_evaluation_statuses!

  def name
    self.student.name
  end

  def ordered_name(order = nil)
    self.student.ordered_name(order)
  end
  
  def group_names(status = nil)
    if status.nil?
      self.student.groups.collect(&:name).join(", ")
    else
      self.student.groups.with_status(status).collect(&:name).join(", ")
    end
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

  def add_absent_results_for_passed_evaluations
    return unless self.suite

    self.suite.evaluations
    .with_target(:all, self.student.gender)
    .where("date < ?", Date.today)
    .each do |evaluation|
      evaluation.results.create(student_id: self.student_id, absent: true) if evaluation.evaluation_participants.blank?
    end
  end

  def add_group_users_to_suite
    if self.group && self.suite
      self.group.users.each { |u| u.add_role :suite_member, self.suite }
    end
  end

  def update_evaluation_statuses!
    self.suite.update_evaluation_statuses! if self.suite
  end


  def student_and_suite_must_have_the_same_instance
    if self.student.try(:instance_id) != self.suite.try(:instance_id)
      errors.add(:student, :invalid_instance)
    end
  end
end
