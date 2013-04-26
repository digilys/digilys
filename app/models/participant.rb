# Link model for students participating in suites
class Participant < ActiveRecord::Base
  belongs_to :student
  belongs_to :suite
  attr_accessible :student_id, :suite_id
end
