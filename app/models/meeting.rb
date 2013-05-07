class Meeting < ActiveRecord::Base
  belongs_to :suite

  attr_accessible :completed,
    :date,
    :name,
    :notes,
    :suite_id

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
