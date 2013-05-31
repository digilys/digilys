class Evaluation < ActiveRecord::Base
  extend Enumerize

  # Column name "type" is not used for inheritance
  self.inheritance_column = :disable_inheritance

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

  enumerize :type,       in: [ :generic, :template, :suite ], predicates: { prefix: true }, scope: true
  enumerize :target,     in: [ :all, :male, :female ],        predicates: { prefix: true }, default: :all
  enumerize :value_type, in: [ :numeric, :boolean, :grade ],  predicates: { prefix: true }, default: :numeric

  accepts_nested_attributes_for :results,
    reject_if: proc { |attributes| attributes[:value].blank? }

  attr_accessible :type,
    :template_id,
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
    :category_list,
    :target,
    :value_type,
    :color_for_true,
    :color_for_false

  serialize :value_aliases, JSON
  serialize :colors, JSON


  validate  :validate_suite
  validate  :validate_date

  validates :name, presence: true

  validates(:max_result,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0
    },
  )
  validates(:red_below,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: :green_above,
      unless: proc { |e| e.red_below.nil? || e.green_above.nil? }
    },
    if: :value_type_numeric?
  )
  validates(:green_above,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: :red_below,
      less_than_or_equal_to: :max_result,
      unless: proc { |e| e.red_below.nil? || e.green_above.nil? }
    },
    if: :value_type_numeric?
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
  2.upto(7) do |i|
    validates(:"stanine#{i}",
      numericality: {
        allow_nil:                true,
        only_integer:             true,
        greater_than_or_equal_to: ->(evaluation) { evaluation.send(:"stanine#{i-1}") || 0 },
        less_than_or_equal_to:    ->(evaluation) { evaluation.send(:"stanine#{i+1}") || evaluation.max_result }
      },
      presence: { if: :stanines? }
    )
  end
  validates(:stanine8,
    numericality: {
      allow_nil:                true,
      only_integer:             true,
      greater_than_or_equal_to: ->(evaluation) { evaluation.stanine7 || 0 }
    },
    presence: { if: :stanines? }
  )

  validates(:color_for_true, :color_for_false,
    inclusion: { in: [:red, :yellow, :green] },
    if: :value_type_boolean?
  )


  before_validation :set_default_values_for_value_type
  before_validation :convert_percentages
  after_update      :touch_results
  before_save       :set_aliases_from_value_type
  before_save       :persist_colors


  def has_regular_suite?
    self.type.try(:suite?) && !self.suite.blank? && !self.suite.is_template?
  end

  def color_for(value)
    return nil if value.nil?

    if self.value_type.numeric?
      if value < self.red_below
        return :red
      elsif value > self.green_above
        return :green
      else
        return :yellow
      end
    else
      return self.colors.try(:[], value.to_s).try(:to_sym)
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

    num_participants = case self.target
    when "all"
      self.participants.size.to_f
    else
      self.participants.with_gender(self.target).size.to_f
    end

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


  def alias_for(value)
    if self.value_aliases.blank?
      value 
    else
      self.value_aliases[value.to_s] || value
    end
  end


  # Virtual accessor for boolean colors
  def color_for_true=(value)
    @color_for_true = value.to_s
  end
  def color_for_true
    (@color_for_true  || self.colors.try(:[], "1")).try(:to_sym)
  end
  def color_for_false=(value)
    @color_for_false = value.to_s
  end
  def color_for_false
    (@color_for_false || self.colors.try(:[], "0")).try(:to_sym)
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
      e.target        = template.target

      e.assign_attributes(attrs)
    end
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


  def validate_suite
    if self.type.try(:suite?)
      errors.add_on_blank(:suite)
    else
      errors.add(:suite, :not_nil) if !self.suite.blank?
    end
  end

  def validate_date
    if self.has_regular_suite?
      if self.date.blank?
        errors.add(:date, :blank)
      elsif !self.date_before_type_cast.is_a?(Date) && self.date_before_type_cast !~ /^\d{4}-\d{2}-\d{2}$/
        errors.add(:date, :invalid)
      end
    else
      errors.add(:date, :not_nil) if !self.date_before_type_cast.blank?
    end
  end

  def set_default_values_for_value_type
    case self.value_type
    when "boolean"
      self.max_result = 1
    end
  end

  BOOLEAN_ALIASES = { "0" => I18n.t(:no), "1" => I18n.t(:yes) }
  GRADE_ALIASES   = {
    "0" => "F",
    "1" => "E",
    "2" => "D",
    "3" => "C",
    "4" => "B",
    "5" => "A"
  }

  def set_aliases_from_value_type
    case self.value_type
    when "grade"
      self.value_aliases = GRADE_ALIASES
    when "boolean"
      self.value_aliases = BOOLEAN_ALIASES
    end
  end

  def persist_colors
    if self.value_type.boolean?
      self.colors = { "0" => self.color_for_false, "1" => self.color_for_true }
    end
  end
end
