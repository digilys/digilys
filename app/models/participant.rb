# Link model for students participating in suites
class Participant < ActiveRecord::Base
  belongs_to :student
  belongs_to :suite

  attr_accessible :student_id, :suite_id

  validates :student, presence:   true
  validates :suite,   presence:   true
  validates :student_id, uniqueness: { scope: :suite_id }

  def name
    self.student.name
  end
  
  def group_names
    self.student.groups.collect(&:name).join(", ")
  end
end
