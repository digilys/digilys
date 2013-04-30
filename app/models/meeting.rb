class Meeting < ActiveRecord::Base
  belongs_to :suite

  attr_accessible :completed,
    :date,
    :name,
    :notes,
    :suite_id

  validates :suite, presence: true
  validates :name,  presence: true
  validates :date,  presence: true, format: { with: /^\d{4}-\d{2}-\d{2}$/ }


  def overdue?
    !self.completed? && self.date < Date.today
  end
end
