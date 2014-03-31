class ColorTable < ActiveRecord::Base
  resourcify

  belongs_to              :instance
  belongs_to              :suite
  has_and_belongs_to_many :evaluations
  has_many                :table_states,    as: :base, order: "name asc", dependent: :destroy
  has_many                :participants,    through: :suite
  has_many                :results,         through: :evaluations
  has_many                :result_students, through: :results,         uniq: true, source: :student
  has_many                :suite_students,  through: :participants,    uniq: true, source: :student
  has_many                :result_groups,   through: :result_students, uniq: true, source: :groups
  has_many                :suite_groups,    through: :suite_students,  uniq: true, source: :groups
  has_many                :users,           through: :roles,           uniq: true, order: "name asc, email asc"

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


  def students
    if self.suite_id
      self.suite_students
    else
      self.result_students
    end
  end

  def group_hierarchy
    if self.suite_id
      groups = self.suite_groups
    else
      groups = self.result_groups
    end

    partition = groups.order("groups.parent_id asc, groups.name asc").group_by(&:parent_id)

    sorted_groups = []

    # The top level has parent_id == nil
    sort_partitioned_groups(sorted_groups, partition, nil)
    return sorted_groups
  end


  def self.regular
    where("suite_id is null")
  end
  def self.with_suites
    where("suite_id is not null")
  end


  private

  def sort_partitioned_groups(sorted_groups, partition, key)
    return if partition[key].blank?

    partition[key].each do |group|
      sorted_groups << group
      sort_partitioned_groups(sorted_groups, partition, group.id)
    end
  end

  def ensure_unique_student_data
    self.student_data.uniq!
  end
end
