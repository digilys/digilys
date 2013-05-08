class Evaluation < ActiveRecord::Base
  belongs_to :template,  class_name: "Evaluation"
  has_many   :instances,
    class_name:  "Evaluation",
    foreign_key: "template_id",
    order:       "date asc",
    dependent:   :nullify

  belongs_to :suite,    inverse_of: :evaluations
  has_many   :results,  dependent:  :destroy
  has_many   :students, through:    :results

  accepts_nested_attributes_for :results

  attr_accessible :template_id,
    :suite_id,
    :max_result,
    :name,
    :date,
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

  validates :name,  presence: true
  validates :date,  presence: true, if: :has_regular_suite?, format: { with: /^\d{4}-\d{2}-\d{2}$/ }
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

  def has_regular_suite?
    !self.suite.blank? && !self.suite.is_template?
  end

  def result_for(student)
    results.where(student_id: student).first
  end

  def red_range
    @red_range = if self.red_below > 1
      0..(self.red_below - 1)
    elsif self.red_below == 1
      0
    else
      nil
    end
  end
  def yellow_range
    @yellow_range = if self.red_below == self.green_above
      self.red_below
    else
      self.red_below..self.green_above
    end
  end
  def green_range
    @green_range = if self.green_above < self.max_result - 1
      (self.green_above + 1)..self.max_result
    elsif self.green_above == self.max_result - 1
      self.max_result
    end
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
  # Generates ruby ranges for the stanine ranges based on stanine boundaries
  def stanine_ranges
    unless @stanine_ranges
      @stanine_ranges = {}

      if self.stanines?
        boundaries = [-1, *self.stanines, self.max_result]

        1.upto(boundaries.length - 1) do |i|
          upper = boundaries[i]
          lower = boundaries[i - 1] + 1

          if upper > lower
            @stanine_ranges[i] = lower..upper
          else
            @stanine_ranges[i] = upper
          end
        end
      end
    end

    return @stanine_ranges
  end


  # Initializes a new evaluation from a template
  def self.new_from_template(template, attrs = {})
    new do |e|
      e.template    = template
      e.name        = template.name
      e.max_result  = template.max_result
      e.red_below   = template.red_below
      e.green_above = template.green_above
      e.stanine1    = template.stanine1
      e.stanine2    = template.stanine2
      e.stanine3    = template.stanine3
      e.stanine4    = template.stanine4
      e.stanine5    = template.stanine5
      e.stanine6    = template.stanine6
      e.stanine7    = template.stanine7
      e.stanine8    = template.stanine8

      e.assign_attributes(attrs)
    end
  end

  # Scope only on templates
  def self.templates
    where(suite_id: nil)
  end
end
