class Suite < ActiveRecord::Base
  extend Enumerize

  has_trash
  default_scope where(arel_table[:deleted_at].eq(nil)) if arel_table[:deleted_at]
  attr_accessible :deleted_at

  resourcify
  has_paper_trail skip: [ :generic_evaluations, :student_data ], meta: { suite_id: ->(s) { s.id } }

  belongs_to :instance
  belongs_to :template,  class_name: "Suite"
  has_many   :children,
    class_name:  "Suite",
    foreign_key: "template_id",
    dependent:   :nullify

  has_many :users,
    through: :roles,
    uniq: true,
    order: "name asc, email asc"

  # It's very important that evaluations is declared before participants
  # otherwise any operation that happens after participants are saved
  # might not affect the correct evaluations
  has_many :evaluations,
    inverse_of: :suite,
    order: :position,
    dependent: :destroy

  has_many :meetings,
    inverse_of: :suite,
    dependent: :destroy

  has_many :activities,
    inverse_of: :suite,
    order: "start_date asc nulls last, end_date asc nulls last, name asc",
    dependent: :destroy

  has_many :participants,
    inverse_of: :suite,
    include: [ :student, :group ],
    dependent: :destroy

  has_many :students, through: :participants

  has_many :groups,
    through: :students,
    order: "groups.name asc",
    uniq: true

  has_many :results, through: :evaluations

  has_many :series,
    order: "name asc",
    dependent: :destroy

  has_one :color_table,
    dependent: :destroy

  has_many :table_states,
    as: :base,
    order: "name asc",
    dependent: :destroy


  accepts_nested_attributes_for :evaluations,
    :meetings,
    :participants

  attr_accessible :name,
    :is_template,
    :template_id,
    :instance,
    :instance_id,
    :evaluations_attributes,
    :meetings_attributes,
    :participants_attributes

  enumerize :status, in: [ :open, :closed ], predicates: true, scope: true, default: :open

  before_save  :ensure_unique_student_data
  after_create :ensure_color_table

  validates :name,     presence: true
  validates :instance, presence: true

  serialize :generic_evaluations, JSON
  serialize :student_data,        JSON


  # Avoiding silly "undefined method `fnew' for Arel::Table:Class"
  def self.deleted(field = nil, value = nil)
    deleted_at = Arel::Table.new(self.table_name)[:deleted_at]
    data = unscoped
    data = data.where(field => value) if field && value
    data.where(deleted_at.not_eq(nil))
  end

  # ActiveRecord refusing to set deleted_at to nil => override Rails' rails-trash.rb
  def restore
    sql = "UPDATE suites SET deleted_at = null WHERE id = #{self.id}"
    ActiveRecord::Base.connection.execute(sql)
  end

  def generic_evaluations(fetch = false)
    if read_attribute(:generic_evaluations).nil?
      write_attribute(:generic_evaluations, [])
    end

    ids = read_attribute(:generic_evaluations)

    if fetch && !ids.blank?
      return Evaluation.
        where(instance_id: self.instance_id, id: ids).
        with_type(:generic).
        order("name asc").
        all
    else
      return ids
    end
  end
  def add_generic_evaluations(*evaluation_ids)
    self.generic_evaluations += evaluation_ids
  end
  def remove_generic_evaluations(*evaluation_ids)
    self.generic_evaluations -= evaluation_ids
  end

  def student_data
    if read_attribute(:student_data).nil?
      write_attribute(:student_data, [])
    end
    return read_attribute(:student_data)
  end
  def add_student_data(*keys)
    self.student_data += keys
  end
  def remove_student_data(*keys)
    self.student_data -= keys
  end

  def update_evaluation_statuses!
    self.evaluations(true).each { |e| e.update_status! }
  end


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

      template.evaluations.order(:created_at).each do |evaluation|
        s.evaluations << Evaluation.new_from_template(evaluation, template_id: evaluation.template_id)
      end

      template.meetings.order(:created_at).each do |meeting|
        s.meetings.build(name: meeting.name, agenda: meeting.agenda)
      end
    end
  end

  def self.in_instance(instance_id)
    self.where(:instance_id => instance_id)
  end


  private

  def ensure_unique_student_data
    self.student_data.uniq!
  end

  def ensure_color_table
    return if self.is_template

    if !self.color_table
      self.create_color_table!(name: self.name)
    elsif self.color_table.new_record?
      self.color_table.save!
    end
  end
end
