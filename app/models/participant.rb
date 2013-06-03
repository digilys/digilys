# Link model for students participating in suites
class Participant < ActiveRecord::Base
  belongs_to :student
  belongs_to :suite
  belongs_to :group

  attr_accessible :student_id,
    :suite_id,
    :group_id

  validates :student, presence:   true
  validates :suite,   presence:   true
  validates :student_id, uniqueness: { scope: :suite_id }

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


  private

  def update_evaluation_statuses!
    self.suite.update_evaluation_statuses! if self.suite
  end
end
