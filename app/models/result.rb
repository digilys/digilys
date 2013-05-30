class Result < ActiveRecord::Base
  belongs_to :evaluation
  belongs_to :student

  attr_accessible :evaluation_id, :student_id, :value

  validates :value, numericality: {
    only_integer:             true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to:    ->(result) { result.evaluation.max_result }
  }
  validates :evaluation, :student, presence: true

  before_save :update_color_and_stanine

  def color
    read_attribute(:color).to_sym
  end
  def color=(value)
    value = value.to_sym if value.respond_to?(:to_sym)
    case value
    when :red, :yellow, :green
      write_attribute(:color, value)
    else
      write_attribute(:color, nil)
    end
  end

  def display_value
    if self.value.blank?
      "" 
    else
      self.evaluation.alias_for(self.value).to_s
    end
  end

  private

  def update_color_and_stanine
    self.color   = self.evaluation.color_for(self.value)
    self.stanine = self.evaluation.stanine_for(self.value)
  end
end
