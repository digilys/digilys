class Result < ActiveRecord::Base
  belongs_to :evaluation
  belongs_to :student

  attr_accessible :evaluation_id, :student_id, :value, :absent

  validates(
    :value,
    numericality: {
      only_integer:             true,
      greater_than_or_equal_to: 0,
      allow_nil:                true,
      less_than_or_equal_to:    ->(result) { result.evaluation.max_result }
    },
    presence: { unless: :absent }
  )
  validates :evaluation, :student, presence: true

  before_validation :ensure_nil_value_on_absent
  before_save       :update_color_and_stanine
  after_create      :update_evaluation_status!
  after_destroy     :update_evaluation_status!


  def color
    read_attribute(:color).try(:to_sym)
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
      "-"
    else
      self.evaluation.alias_for(self.value).to_s
    end
  end

  private

  def update_color_and_stanine
    self.color   = self.evaluation.color_for(self.value)
    self.stanine = self.evaluation.stanine_for(self.value)
  end

  def update_evaluation_status!
    self.evaluation.update_status! if self.evaluation
  end

  def ensure_nil_value_on_absent
    self.value = nil if self.absent?
  end
end
