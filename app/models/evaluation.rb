class Evaluation < ActiveRecord::Base
  belongs_to :suite
  has_many   :results
  has_many   :students, through: :results

  attr_accessible :suite_id, :max_result, :name, :red_below, :green_above

  validates :suite, presence: true
  validates :name,  presence: true
  validates :max_result, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }
  validates :red_below, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: :green_above
  }
  validates :green_above, numericality: {
    only_integer: true,
    greater_than_or_equal_to: :red_below,
    less_than_or_equal_to: :max_result
  }

  def result_for(student)
    results.where(:student_id => student).first
  end
end
