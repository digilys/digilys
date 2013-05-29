class Activity < ActiveRecord::Base
  extend Enumerize

  # Column name "type" is not used for inheritance
  self.inheritance_column = :disable_inheritance

  belongs_to :suite,   inverse_of: :activities
  belongs_to :meeting, inverse_of: :activities

  has_and_belongs_to_many :students
  has_and_belongs_to_many :groups

  attr_accessible :description,
    :name,
    :notes,
    :status,
    :suite_id,
    :type,
    :student_ids,
    :group_ids

  validates :suite, presence: true
  validates :name,  presence: true

  enumerize :type,   in: [ :action, :inquiry ], predicates: true, scope: true, default: :action
  enumerize :status, in: [ :open, :closed ],    predicates: true, scope: true, default: :open

  before_validation :set_suite_from_meeting


  private

  def set_suite_from_meeting
    self.suite = self.meeting.suite if self.suite_id.nil? && !self.meeting.nil?
  end
end
