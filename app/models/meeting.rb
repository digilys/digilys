class Meeting < ActiveRecord::Base
  belongs_to :suite,      inverse_of: :meetings
  has_many   :activities, inverse_of: :meeting

  accepts_nested_attributes_for :activities,
    reject_if: proc { |attributes| attributes[:name].blank? && attributes[:description].blank? }

  attr_accessible :completed,
    :date,
    :agenda,
    :name,
    :notes,
    :suite_id,
    :activities_attributes

  validates :suite, presence: true
  validates :name,  presence: true
  validates :date,  presence: true, if: :has_regular_suite?, format: { with: /^\d{4}-\d{2}-\d{2}$/ }


  def has_regular_suite?
    !self.suite.blank? && !self.suite.is_template?
  end

  def overdue?
    !self.completed? && self.date < Date.today
  end
end
