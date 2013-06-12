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
    :start_date,
    :end_date,
    :notes,
    :status,
    :suite_id,
    :type,
    :student_ids,
    :group_ids,
    :students_and_groups

  validates :suite, presence: true
  validates :name,  presence: true
  validate  :validate_date_format

  enumerize :type,   in: [ :action, :inquiry ], predicates: true, scope: true, default: :action
  enumerize :status, in: [ :open, :closed ],    predicates: true, scope: true, default: :open

  before_validation :set_suite_from_meeting
  before_validation :parse_students_and_groups

  after_save :clear_students_and_groups

  def overdue?
    !self.closed? && self.end_date && self.end_date < Date.today
  end


  # Virtual attribute for a comma separated list of student ids and group ids.
  # The ids should have the prefix s-#{id} and g-#{id} for students and groups,
  # respectively
  attr_accessor :students_and_groups

  def students_and_groups_select2_data
    self.students.collect { |s| { id: "s-#{s.id}", text: s.name } } +
      self.groups.collect { |g| { id: "g-#{g.id}", text: g.name } }
  end


  def self.where_suite_manager(user)
    query = <<-SQL
      suite_id in (
        select
          resource_id
        from
          roles
          left join users_roles on roles.id = users_roles.role_id
        where
          resource_type = 'Suite'
          and name = 'suite_manager'
          and user_id = ?
      )
    SQL

    where(query, user.id)
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

  def validate_date_format
    start_date = self.start_date_before_type_cast
    if !start_date.blank? && !start_date.is_a?(Date) && start_date !~ /^\d{4}-\d{2}-\d{2}$/
      errors.add(:start_date, :invalid)
    end
    end_date = self.end_date_before_type_cast
    if !end_date.blank? && !end_date.is_a?(Date) && end_date !~ /^\d{4}-\d{2}-\d{2}$/
      errors.add(:end_date, :invalid)
    end
  end
end
