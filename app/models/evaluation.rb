class Evaluation < ActiveRecord::Base
  belongs_to :suite
  has_many   :results
  has_many   :students, through: :results

  accepts_nested_attributes_for :results

  attr_accessible :suite_id,
    :max_result,
    :name,
    :red_below,
    :green_above,
    :stanine1,
    :stanine2,
    :stanine3,
    :stanine4,
    :stanine5,
    :stanine6,
    :stanine7,
    :stanine8,
    :results_attributes

  validates :suite, presence: true
  validates :name, presence: true
  validates(:max_result,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0
    },
  )
  validates(:red_below,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: :green_above
    },
    presence: { if: :stanines? }
  )
  validates(:green_above,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: :red_below,
      less_than_or_equal_to: :max_result
    },
    presence: { if: :stanines? }
  )

  validates(:stanine1,
    numericality: {
      allow_nil:                true,
      only_integer:             true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to:    ->(evaluation) { evaluation.stanine2 || evaluation.max_result }
    },
    presence: { if: :stanines? }
  )
  validates(:stanine2,
    numericality: {
      allow_nil:                true,
      only_integer:             true,
      greater_than_or_equal_to: ->(evaluation) { evaluation.stanine1 || 0 },
      less_than_or_equal_to:    ->(evaluation) { evaluation.stanine3 || evaluation.max_result }
    },
    presence: { if: :stanines? }
  )
  validates(:stanine3,
    numericality: {
      allow_nil:                true,
      only_integer:             true,
      greater_than_or_equal_to: ->(evaluation) { evaluation.stanine2 || 0 },
      less_than_or_equal_to:    ->(evaluation) { evaluation.stanine4 || evaluation.max_result }
    },
    presence: { if: :stanines? }
  )
  validates(:stanine4,
    numericality: {
      allow_nil:                true,
      only_integer:             true,
      greater_than_or_equal_to: ->(evaluation) { evaluation.stanine3 || 0 },
      less_than_or_equal_to:    ->(evaluation) { evaluation.stanine5 || evaluation.max_result }
    },
    presence: { if: :stanines? }
  )
  validates(:stanine5,
    numericality: {
      allow_nil:                true,
      only_integer:             true,
      greater_than_or_equal_to: ->(evaluation) { evaluation.stanine4 || 0 },
      less_than_or_equal_to:    ->(evaluation) { evaluation.stanine6 || evaluation.max_result }
    },
    presence: { if: :stanines? }
  )
  validates(:stanine6,
    numericality: {
      allow_nil:                true,
      only_integer:             true,
      greater_than_or_equal_to: ->(evaluation) { evaluation.stanine5 || 0 },
      less_than_or_equal_to:    ->(evaluation) { evaluation.stanine7 || evaluation.max_result }
    },
    presence: { if: :stanines? }
  )
  validates(:stanine7,
    numericality: {
      allow_nil:                true,
      only_integer:             true,
      greater_than_or_equal_to: ->(evaluation) { evaluation.stanine6 || 0 },
      less_than_or_equal_to:    ->(evaluation) { evaluation.stanine8 || evaluation.max_result }
    },
    presence: { if: :stanines? }
  )
  validates(:stanine8,
    numericality: {
      allow_nil:                true,
      only_integer:             true,
      greater_than_or_equal_to: ->(evaluation) { evaluation.stanine7 || 0 }
    },
    presence: { if: :stanines? }
  )

  def result_for(student)
    results.where(:student_id => student).first
  end

  # Indicates if this evaluation uses stanine values
  def stanines?
    self.stanines.any? { |s| !s.nil? }
  end
  def stanines
    @stanines ||= [
      self.stanine1,
      self.stanine2,
      self.stanine3,
      self.stanine4,
      self.stanine5,
      self.stanine6,
      self.stanine7,
      self.stanine8
    ]
  end
end
