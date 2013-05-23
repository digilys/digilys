class Evaluation < ActiveRecord::Base
  belongs_to :template,  class_name: "Evaluation"
  has_many   :instances,
    class_name:  "Evaluation",
    foreign_key: "template_id",
    order:       "date asc",
    dependent:   :nullify

  belongs_to :suite,        inverse_of: :evaluations
  has_many   :participants, through:    :suite
  has_many   :results,      dependent:  :destroy
  has_many   :students,     through:    :results

  acts_as_taggable_on :categories

  accepts_nested_attributes_for :results

  attr_accessible :template_id,
    :suite_id,
    :max_result,
    :name,
    :description,
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
    :results_attributes,
    :category_list

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


  before_validation :convert_percentages
  after_update      :touch_results


  def has_regular_suite?
    !self.suite.blank? && !self.suite.is_template?
  end

  def color_for(value)
    if value.nil?
      nil
    elsif value < self.red_below
      :red
    elsif value > self.green_above
      :green
    else
      :yellow
    end
  end
  def stanine_for(value)
    if !value.blank? && self.stanines?
      stanine = 1
      prev = -1

      self.stanines.each do |boundary|
        stanine += 1 if boundary < value || boundary == value && prev == boundary
        prev = boundary
      end

      return stanine
    else
      return nil
    end
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


  # Builds a percentage distribution of the results
  # of the following form:
  #
  #  {
  #     not_reported: 10,
  #     red: 20,
  #     yellow: 30
  #     green: 40
  #  }
  def result_distribution
    return nil if self.results.blank?

    result_distribution = {}

    num_participants = self.participants.size.to_f

    result_distribution[:not_reported] = ((num_participants - self.results.length.to_f) / num_participants) * 100.0

    colors = { red: 0, yellow: 0, green: 0 }
    self.results.each do |result|
      colors[result.color] += 1
    end
    
    colors.each_pair do |color, num|
      result_distribution[color] = (num.to_f / num_participants) * 100.0
    end

    return result_distribution
  end


  # Initializes a new evaluation from a template
  def self.new_from_template(template, attrs = {})
    new do |e|
      e.template      = template
      e.name          = template.name
      e.description   = template.description
      e.max_result    = template.max_result
      e.red_below     = template.red_below
      e.green_above   = template.green_above
      e.stanine1      = template.stanine1
      e.stanine2      = template.stanine2
      e.stanine3      = template.stanine3
      e.stanine4      = template.stanine4
      e.stanine5      = template.stanine5
      e.stanine6      = template.stanine6
      e.stanine7      = template.stanine7
      e.stanine8      = template.stanine8
      e.category_list = template.category_list

      e.assign_attributes(attrs)
    end
  end

  # Scope only on templates
  def self.templates
    where(suite_id: nil)
  end


  private

  def convert_percentages
    return unless self.max_result

    %w(red_below green_above).each do |attr|
      value = self.attributes_before_type_cast[attr]

      if value.is_a?(String) &&
          /\A([+-]?\d+)\s*%\Z/.match(value) # Regex used for integer validation + a percent sign at the end
        percentage = $1.to_f                # $1 contains the number matched by the regex
        send(:"#{attr}=", (self.max_result * percentage/100.0).to_i)
      end
    end
  end

  # If any of these attributes are changed, touch the results
  TOUCH_RESULT_ON_CHANGED = %w(
    red_below
    green_above
    stanine1
    stanine2
    stanine3
    stanine4
    stanine5
    stanine6
    stanine7
    stanine8
  )

  def touch_results
    # Intersect the changed array with the touch on array
    if !(TOUCH_RESULT_ON_CHANGED & self.changed).blank?
      self.results.map(&:save)
    end
  end
end
