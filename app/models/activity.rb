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
    :group_ids,
    :students_and_groups

  validates :suite, presence: true
  validates :name,  presence: true

  enumerize :type,   in: [ :action, :inquiry ], predicates: true, scope: true, default: :action
  enumerize :status, in: [ :open, :closed ],    predicates: true, scope: true, default: :open

  before_validation :set_suite_from_meeting
  before_validation :parse_students_and_groups

  after_save :clear_students_and_groups


  # Virtual attribute for a comma separated list of student ids and group ids.
  # The ids should have the prefix s-#{id} and g-#{id} for students and groups,
  # respectively
  attr_accessor :students_and_groups

  def students_and_groups_select2_data
    self.students.collect { |s| { id: "s-#{s.id}", text: s.name } } +
      self.groups.collect { |g| { id: "g-#{g.id}", text: g.name } }
  end

  private

  def set_suite_from_meeting
    self.suite = self.meeting.suite if self.suite_id.nil? && !self.meeting.nil?
  end

  def parse_students_and_groups
    return if @students_and_groups.blank?

    student_ids = []
    group_ids   = []

    @students_and_groups.split(",").each do |id|
      case id.strip
      when /g-(\d+)/
        group_ids << $1
      when /s-(\d+)/
        student_ids << $1
      end
    end

    self.student_ids = student_ids.uniq
    self.group_ids   = group_ids.uniq
  end

  def clear_students_and_groups
    @students_and_groups = nil
  end
end
