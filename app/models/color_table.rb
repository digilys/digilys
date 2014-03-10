class ColorTable < ActiveRecord::Base
  belongs_to              :instance
  belongs_to              :suite
  has_and_belongs_to_many :evaluations
  has_many                :table_states,        as: :base, order: "name asc", dependent: :destroy

  attr_accessible :name,
    :student_data,
    :suite,
    :suite_id,
    :instance,
    :instance_id,
    :evaluation_ids

  validates :name,     presence: true
  validates :instance, presence: { unless: :suite }, inclusion: { in: [nil], if: :suite }

  serialize :student_data, JSON

  before_save :ensure_unique_student_data


  def student_data
    if read_attribute(:student_data).nil?
      write_attribute(:student_data, [])
    end
    return read_attribute(:student_data)
  end

  def generic_evaluations
    self.evaluations.with_type(:generic).order("id asc")
  end
  def suite_evaluations
    self.evaluations.with_type(:suite).order("date asc, id asc")
  end

  def evaluations_select2_data
    self.evaluations.
      includes(:suite).
      collect { |e| { id: e.id, text: "#{e.name}#{", #{e.suite.name}" if e.suite}" } }
  end


  def self.regular
    where("suite_id is null")
  end
  def self.with_suites
    where("suite_id is not null")
  end


  private

  def ensure_unique_student_data
    self.student_data.uniq!
  end
end
