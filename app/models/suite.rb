class Suite < ActiveRecord::Base
  belongs_to :template,  class_name: "Suite"
  has_many   :instances,
    class_name:  "Suite",
    foreign_key: "template_id",
    dependent:   :nullify

  has_many :participants, inverse_of: :suite,     include: :student,   dependent: :destroy
  has_many :students,     through: :participants, order: "name asc"
  has_many :evaluations,  inverse_of: :suite,     dependent: :destroy
  has_many :results,      through: :evaluations
  has_many :meetings,     inverse_of: :suite,     dependent: :destroy

  accepts_nested_attributes_for :evaluations,
    :meetings,
    :participants

  attr_accessible :name,
    :is_template,
    :template_id,
    :evaluations_attributes,
    :meetings_attributes,
    :participants_attributes

  validates :name, presence: true


  def self.template
    where(is_template: true)
  end
  def self.regular
    where(is_template: false)
  end

  def self.new_from_template(template, attrs = {})
    new do |s|
      s.name = template.name

      s.assign_attributes(attrs)

      template.evaluations.each do |evaluation|
        s.evaluations << Evaluation.new_from_template(evaluation)
      end

      template.meetings.each do |meeting|
        s.meetings.build(name: meeting.name)
      end
    end
  end
end
