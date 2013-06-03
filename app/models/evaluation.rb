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
  enumerize :status,     in: [ :empty, :partial, :complete ], predicates: { prefix: true }, scope: true, default: :empty

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
    :color_for_false,
    :color_for_grade_a,
    :color_for_grade_b,
    :color_for_grade_c,
    :color_for_grade_d,
    :color_for_grade_e,
    :color_for_grade_f,
    :stanine_for_grade_a,
    :stanine_for_grade_b,
    :stanine_for_grade_c,
    :stanine_for_grade_d,
    :stanine_for_grade_e,
    :stanine_for_grade_f

  serialize :value_aliases, JSON
  serialize :colors,        JSON
  serialize :stanines,      JSON


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

  VALID_COLORS = [:red, :yellow, :green]

  validates(:color_for_true, :color_for_false,
    inclusion: { in: VALID_COLORS },
    if: :value_type_boolean?
  )

  GRADES = ("a".."f").to_a.reverse
  
  GRADES.each_with_index do |grade, i|
    validates(:"color_for_grade_#{grade}",
      numericality: {
        only_integer: true,
        greater_than_or_equal_to:
          ->(evaluation) { i <= 0 ? 1 : evaluation.send(:"color_for_grade_#{GRADES[i-1]}") || 1 },
        less_than_or_equal_to:
          ->(evaluation) { i >= 5 ? 3 : evaluation.send(:"color_for_grade_#{GRADES[i+1]}") || 3 },
        message: :faulty_grade_color
      },
      if: :value_type_grade?
    )
    validates(:"stanine_for_grade_#{grade}",
      numericality: {
        allow_nil: true,
        allow_blank: true,
        only_integer: true,
        greater_than_or_equal_to:
          ->(evaluation) { i <= 0 ? 1 : evaluation.send(:"stanine_for_grade_#{GRADES[i-1]}") || 1 },
        less_than_or_equal_to:
          ->(evaluation) { i >= 5 ? 9 : evaluation.send(:"stanine_for_grade_#{GRADES[i+1]}") || 9 },
        message: :faulty_grade_stanine
      },
      presence: { if: :stanine_for_grades? },
      if: :value_type_grade?
    )
  end


  before_validation :set_default_values_for_value_type
  before_validation :convert_percentages
  after_update      :touch_results
  before_save       :set_aliases_from_value_type
  before_save       :persist_colors_and_stanines


  def has_regular_suite?
    self.type.try(:suite?) && !self.suite.blank? && !self.suite.is_template?
  end

  def color_for(value)
    return nil if value.nil?

    case self.value_type.to_sym
    when :numeric
      if value < self.red_below
        return :red
      elsif value > self.green_above
        return :green
      else
        return :yellow
      end
    when :boolean
      return self.colors.try(:[], value.to_s).try(:to_sym)
    when :grade
      color_num = self.colors.try(:[], value.to_s)
      return VALID_COLORS[color_num - 1] if color_num
    end
    return nil
  end
  def stanine_for(value)
    return nil if value.blank?

    case self.value_type.to_sym
    when :numeric
      return nil unless self.stanines?

      stanine = 1
      prev = -1

      self.stanine_limits.each do |boundary|
        stanine += 1 if boundary < value || boundary == value && prev == boundary
        prev = boundary
      end

      return stanine
    when :grade
      return self.stanines.try(:[], value.to_s)
    end
    return nil
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
    self.stanine_limits.any? { |s| !s.nil? }
  end
  def stanine_limits
    @stanine_limits ||= [
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
        boundaries = [-1, *self.stanine_limits, self.max_result]

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

  # Virtual accessors for grade colors and stanines
  GRADES.each_with_index do |g, i|

    attr_writer :"color_for_grade_#{g}", :"stanine_for_grade_#{g}"

    # Enforce integer
    define_method(:"color_for_grade_#{g}") do
      v = instance_variable_get("@color_for_grade_#{g}")
      v ||= self.colors.try(:[], i.to_s)
      v.blank? ? nil : v.to_i
    end
    define_method(:"stanine_for_grade_#{g}") do
      v = instance_variable_get("@stanine_for_grade_#{g}")
      v ||= self.stanines.try(:[], i.to_s)
      v.blank? ? nil : v.to_i
    end
  end

  def stanine_for_grades?
    !@stanine_for_grade_a.blank? ||
      !@stanine_for_grade_b.blank? ||
      !@stanine_for_grade_c.blank? ||
      !@stanine_for_grade_d.blank? ||
      !@stanine_for_grade_e.blank? ||
      !@stanine_for_grade_f.blank?
  end

  def update_status!
    num_results = self.results(true).count(:all)
    num_participants = self.participants(true).count(:all)

    if num_results > 0 && num_results < num_participants
      self.status = :partial
    elsif num_results > 0 && num_results >= num_participants
      self.status = :complete
    else
      self.status = :empty
    end

    self.save!
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
      e.type          = template.type

      e.assign_attributes(attrs)
    end
  end

  def self.overdue
    with_status(:empty, :partial).where([ "date < ?", Date.today ])
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
    when "grade"
      self.max_result = 5
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

  def persist_colors_and_stanines
    case self.value_type.to_sym
    when :boolean
      self.colors = { "0" => self.color_for_false, "1" => self.color_for_true }
    when :grade
      self.colors = {
        "0" => self.color_for_grade_f,
        "1" => self.color_for_grade_e,
        "2" => self.color_for_grade_d,
        "3" => self.color_for_grade_c,
        "4" => self.color_for_grade_b,
        "5" => self.color_for_grade_a
      }
      self.stanines = {
        "0" => self.stanine_for_grade_f,
        "1" => self.stanine_for_grade_e,
        "2" => self.stanine_for_grade_d,
        "3" => self.stanine_for_grade_c,
        "4" => self.stanine_for_grade_b,
        "5" => self.stanine_for_grade_a
      }
    end
  end
end
