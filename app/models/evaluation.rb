class Evaluation < ActiveRecord::Base
  extend Enumerize
  include RailsSortable::Model

  has_trash
  default_scope where(arel_table[:deleted_at].eq(nil)) if arel_table[:deleted_at]
  attr_accessible :deleted_at

  has_paper_trail meta: { suite_id: ->(s) { s.suite_id } }

  # Column name "type" is not used for inheritance
  self.inheritance_column = :disable_inheritance

  belongs_to :instance

  belongs_to :template,  class_name: "Evaluation"
  has_many   :children,
    class_name:  "Evaluation",
    foreign_key: "template_id",
    order:       "date asc",
    dependent:   :nullify

  has_and_belongs_to_many :evaluation_participants, class_name: "Participant", include: :student
  has_and_belongs_to_many :users
  has_and_belongs_to_many :color_tables

  belongs_to :suite,              inverse_of: :evaluations
  acts_as_list scope: :suite

  belongs_to :series
  has_many   :suite_participants, through:    :suite,       source: :participants
  has_many   :results,            include:    :student,     dependent: :destroy
  has_many   :students,           through:    :results

  set_sortable :sort

  acts_as_taggable_on :categories

  enumerize :type,       in: [ :generic, :template, :suite ], predicates: { prefix: true }, scope: true
  enumerize :target,     in: [ :all, :male, :female ],        predicates: { prefix: true }, scope: true, default: :all
  enumerize :value_type, in: [ :numeric, :boolean, :grade ],  predicates: { prefix: true }, default: :numeric
  enumerize :status,     in: [ :empty, :partial, :complete ], predicates: { prefix: true }, scope: true, default: :empty

  accepts_nested_attributes_for :results,
    reject_if: proc { |attributes| attributes[:absent] != "1" && attributes[:value].blank? },
    allow_destroy: true

  attr_accessible :type,
    :instance,
    :instance_id,
    :template_id,
    :suite,
    :suite_id,
    :max_result,
    :name,
    :description,
    :date,
    :colors_serialized,
    :stanines_serialized,
    :target,
    :value_type,
    :category_list,
    :red_min,
    :red_max,
    :yellow_min,
    :yellow_max,
    :green_min,
    :green_max,
    :stanine1_min,
    :stanine1_max,
    :stanine2_min,
    :stanine2_max,
    :stanine3_min,
    :stanine3_max,
    :stanine4_min,
    :stanine4_max,
    :stanine5_min,
    :stanine5_max,
    :stanine6_min,
    :stanine6_max,
    :stanine7_min,
    :stanine7_max,
    :stanine8_min,
    :stanine8_max,
    :stanine9_min,
    :stanine9_max,
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
    :stanine_for_grade_f,
    :results_attributes,
    :students_and_groups,
    :user_ids,
    :series,
    :series_id

  serialize :value_aliases, JSON
  serialize :colors,        JSON
  serialize :stanines,      JSON


  validate  :validate_instance
  validate  :validate_suite
  validate  :validate_date
  validate  :validate_deleted_at

  validates :name, presence: true

  validates(:max_result,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0
    },
  )

  VALID_COLORS = [:red, :yellow, :green]

  VALID_COLORS.each do |color|
    validates(:"#{color}_min",
      numericality: {
        allow_nil:                true,
        only_integer:             true,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to:    proc { |e| e.send(:"#{color}_max").to_i }
      },
      if: :value_type_numeric?
    )
    validates(:"#{color}_max",
      numericality: {
        allow_nil:                true,
        only_integer:             true,
        greater_than_or_equal_to: proc { |e| e.send(:"#{color}_min").to_i },
        less_than_or_equal_to:    :max_result
      },
      if: :value_type_numeric?
    )
  end

  1.upto(9) do |i|
    validates(:"stanine#{i}_min",
      numericality: {
        allow_nil:                true,
        only_integer:             true,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to:    proc { |e| e.send(:"stanine#{i}_max").to_i }
      },
      if: :value_type_numeric?
    )
    validates(:"stanine#{i}_max",
      numericality: {
        allow_nil:                true,
        only_integer:             true,
        greater_than_or_equal_to: proc { |e| e.send(:"stanine#{i}_min").to_i },
        less_than_or_equal_to:    :max_result,
      },
      if: :value_type_numeric?
    )
  end

  validates(:color_for_true, :color_for_false,
    inclusion: { in: VALID_COLORS },
    if: :value_type_boolean?
  )

  GRADES = ("a".."f").to_a.reverse

  GRADES.each_with_index do |grade, i|
    validates(:"color_for_grade_#{grade}",
      numericality: {
        only_integer:             true,
        greater_than_or_equal_to: 1,
        less_than_or_equal_to:    3,
        message:                  :faulty_grade_color
      },
      if: :value_type_grade?
    )
    validates(:"stanine_for_grade_#{grade}",
      numericality: {
        allow_nil:                true,
        allow_blank:              true,
        only_integer:             true,
        greater_than_or_equal_to: 1,
        less_than_or_equal_to:    9,
        message:                  :faulty_grade_stanine
      },
      presence: { if: :has_grade_stanines? },
      if: :value_type_grade?
    )
  end

  before_validation :parse_students_and_groups
  before_validation :set_default_values_for_value_type
  before_save       :set_aliases_from_value_type
  before_save       :persist_colors_and_stanines
  before_save       :create_series_from_name
  after_create      :add_to_suite_color_table
  after_update      :touch_results
  after_save        :update_series_current!
  after_save        :destroy_empty_series!
  after_destroy     :destroy_empty_series!


  # Avoiding silly "undefined method `fnew' for Arel::Table:Class"
  def self.deleted(field = nil, value = nil)
    deleted_at = Arel::Table.new(self.table_name)[:deleted_at]
    data = unscoped
    data = data.where(field => value) if field && value
    data.where(deleted_at.not_eq(nil))
  end

  # ActiveRecord refusing to set deleted_at to nil => override Rails' rails-trash.rb
  def restore
    sql = "UPDATE evaluations SET deleted_at = null WHERE id = #{self.id}"
    ActiveRecord::Base.connection.execute(sql)
  end

  def colors_serialized
    self.colors.try(:to_json)
  end
  def colors_serialized=(value)
    self.colors = !value.blank? ? JSON.parse(value) : nil
  end
  def stanines_serialized
    self.stanines.try(:to_json)
  end
  def stanines_serialized=(value)
    self.stanines = !value.blank? ? JSON.parse(value) : nil
  end


  def overdue?
    !self.status.complete? && self.date < Date.today
  end
  # Makes it compatible with Meeting
  def completed?
    self.status.complete?
  end

  def has_regular_suite?
    self.type.try(:suite?) && !self.suite.blank? && !self.suite.is_template?
  end

  def color_for(value)
    return nil if value.nil?

    case self.value_type.to_sym
    when :numeric
      return nil if self.colors.blank?
      self.colors.each do |color, range|
        return color.to_sym if value >= range["min"] && value <= range["max"]
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
      return nil if self.stanines.blank?
      self.stanines.each do |stanine, range|
        return stanine.to_i if value >= range["min"] && value <= range["max"]
      end
    when :grade
      return self.stanines.try(:[], value.to_s)
    end
    return nil
  end

  def result_for(student)
    results.where(student_id: student).first
  end

  # Indicates if this evaluation uses stanine values
  def stanines?
    !self.stanines.blank?
  end


  def participants(force_reload = false)
    if !self.evaluation_participants(force_reload).blank?
      self.evaluation_participants
    elsif self.target.all?
      self.suite_participants(force_reload)
    else
      self.suite_participants(force_reload).with_gender(self.target)
    end
  end

  def participant_count(force_reload = false)
    self.participants(force_reload).length.to_f
  end

  def participants_without_result(force_reload = true)
    self.participants(force_reload).where([ "student_id not in (select student_id from results where evaluation_id = ?)", self.id ])
  end

  # Virtual attribute for a comma separated list of student ids and group ids.
  # The ids should have the prefix s-#{id} and g-#{id} for students and groups,
  # respectively
  attr_accessor :students_and_groups

  def students_and_groups_select2_data
    self.evaluation_participants.collect { |p| { id: "s-#{p.student.id}", text: p.student.name } }
  end

  def users_select2_data
    self.users.collect { |u| { id: u.id, text: "#{u.name}, #{u.email}" } }
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

    num_missing = self.participants_without_result.size.to_f
    total       = self.results.size.to_f + num_missing

    result_distribution[:not_reported] = (num_missing / total) * 100.0

    colors = { red: 0, yellow: 0, green: 0, absent: 0 }
    self.results.each do |result|
      colors[result.color || :absent] += 1
    end

    colors.each_pair do |color, num|
      result_distribution[color] = (num.to_f / total) * 100.0
    end

    return result_distribution
  end

  # Builds an amount distribution of the result stanine values
  # of the following form:
  #
  #  {
  #     1: 5,
  #     2: 3,
  #     ...
  #     9: 4
  #  }
  #
  # Missing stanine values are not included in the hash
  def stanine_distribution
    @stanine_distribution ||= self.results.reorder('').group(:stanine).count
  end


  def alias_for(value)
    if self.value_aliases.blank?
      value
    else
      self.value_aliases[value.to_s] || value
    end
  end


  # Virtual accessors for numeric colors and stanines
  attr_writer :red_min, :red_max, :yellow_min, :yellow_max, :green_min, :green_max
  def red_min
    unless defined?(@red_min)
      @red_min = self.colors.try(:[], "red").try(:[], "min")
    end
    @red_min
  end
  def red_max
    unless defined?(@red_max)
      @red_max = self.colors.try(:[], "red").try(:[], "max")
    end
    @red_max
  end
  def yellow_min
    unless defined?(@yellow_min)
      @yellow_min = self.colors.try(:[], "yellow").try(:[], "min")
    end
    @yellow_min
  end
  def yellow_max
    unless defined?(@yellow_max)
      @yellow_max = self.colors.try(:[], "yellow").try(:[], "max")
    end
    @yellow_max
  end
  def green_min
    unless defined?(@green_min)
      @green_min = self.colors.try(:[], "green").try(:[], "min")
    end
    @green_min
  end
  def green_max
    unless defined?(@green_max)
      @green_max = self.colors.try(:[], "green").try(:[], "max")
    end
    @green_max
  end

  1.upto(9).each do |i|
    attr_writer :"stanine#{i}_min", :"stanine#{i}_max"
    define_method(:"stanine#{i}_min") do
      v = instance_variable_get("@stanine#{i}_min")
      v ||= self.stanines.try(:[], i.to_s).try(:[], "min")
      v.blank? ? nil : v
    end
    define_method(:"stanine#{i}_max") do
      v = instance_variable_get("@stanine#{i}_max")
      v ||= self.stanines.try(:[], i.to_s).try(:[], "max")
      v.blank? ? nil : v
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

  def update_status!
    num_results = self.results(true).count(:all)
    num_participants = self.participant_count(true)

    prev_status = self.status
    if num_results > 0 && num_results < num_participants
      self.status = :partial
    elsif num_results > 0 && num_results >= num_participants
      self.status = :complete
    else
      self.status = :empty
    end

    if self.suite && prev_status == "empty" && self.status != "empty" && self.suite.color_table
      self.suite.color_table.table_states.each do |state|
        state.data["hiddenColumns"] << "evaluation-#{self.id}" unless state.data["hiddenColumns"].include?("evaluation-#{self.id}")
        state.save!
      end
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
      e.colors        = template.colors
      e.stanines      = template.stanines
      e.category_list = template.category_list
      e.target        = template.target
      e.type          = template.type
      e.value_type    = template.value_type
      e.series        = template.series        if template.series_id

      e.assign_attributes(attrs)
    end
  end


  def self.in_instance(instance_id)
    self.joins(:suite).where("suites.instance_id" => instance_id)
  end

  def self.search_in_instance(instance_id, search_params)
    q = where([ "suites.instance_id = :instance_id or evaluations.instance_id = :instance_id", instance_id: instance_id ])

    # Ransack joins the suites table if the search params contains
    # parameters like suite_name
    unless search_params.keys.any? { |k| k =~ /suite_/ }
      q = q.joins("left join suites on suites.id = evaluations.suite_id")
    end

    q.search(search_params).result
  end

  def self.overdue
    with_status(:empty, :partial).where([ "date < ?", Date.today ])
  end
  def self.upcoming
    where([ "date >= ?", Date.today ])
  end

  def self.where_suite_member(user)
    query = <<-SQL
      suite_id in (
        select
          resource_id
        from
          roles
          left join users_roles on roles.id = users_roles.role_id
        where
          resource_type = 'Suite'
          and (name = 'suite_member' or name = 'suite_manager')
          and user_id = ?
      )
    SQL

    where(query, user.id)
  end

  def self.with_stanines
    # The check for null as a string is due to the fact that the stanines
    # field is a seralized field, and a nil value will be serialized as "null"
    where("stanines is not null and stanines != 'null'")
  end

  def self.without_explicit_users
    where("evaluations.id not in (select evaluation_id from evaluations_users)")
  end

  # For all evaluations belonging to series, remove all but
  # the current evaluation for each series. This does not touch
  # evaluations not belonging to a series.
  def self.only_series_currents
    where([ "series_id is null or is_series_current = ?", true ])
  end

  # Returns missing generic evalutions for a specific object
  # that has an attribute .generic_evaluations which is an array
  # with associated generic evaluations
  def self.missing_generics_for(obj)
    ctx = where(instance_id: obj.instance_id).
      with_type(:generic).
      order("name asc")

    if !(ids = obj.generic_evaluations).blank?
      ctx = ctx.where("id not in (?)", ids)
    end

    return ctx
  end

  # Returns a cache key which covers all generic evaluations
  def self.generic_cache_key
    with_type(:generic).maximum("updated_at").try(:to_s, cache_timestamp_format)
  end


  def has_grade_stanines?
    return !@stanine_for_grade_a.blank? ||
      !@stanine_for_grade_b.blank? ||
      !@stanine_for_grade_c.blank? ||
      !@stanine_for_grade_d.blank? ||
      !@stanine_for_grade_e.blank? ||
      !@stanine_for_grade_f.blank?
  end
  def has_numeric_stanines?
    return !stanine1_min.blank? ||
      !stanine1_max.blank? ||
      !stanine2_min.blank? ||
      !stanine2_max.blank? ||
      !stanine3_min.blank? ||
      !stanine3_max.blank? ||
      !stanine4_min.blank? ||
      !stanine4_max.blank? ||
      !stanine5_min.blank? ||
      !stanine5_max.blank? ||
      !stanine6_min.blank? ||
      !stanine6_max.blank? ||
      !stanine7_min.blank? ||
      !stanine7_max.blank? ||
      !stanine8_min.blank? ||
      !stanine8_max.blank? ||
      !stanine9_min.blank? ||
      !stanine9_max.blank?
  end

  def series_name
    if self.series_id && self.series_id > 0
      return self.series.name
    elsif self.series_id == 0
      return self.attributes_before_type_cast["series_id"]
    end
  end


  private

  def upper_limit_for_stanine(stanine)
    if self.value_type_numeric? && self.stanines
      stanine.downto(1) do |i|
        return self.stanines[i.to_s]["max"].to_i if self.stanines[i.to_s]
      end
    end
    return nil
  end


  def touch_results
    self.results(true).map(&:save) if self.colors_changed? || self.stanines_changed?
  end

  def add_to_suite_color_table
    if self.type.suite? && self.suite.color_table
      self.suite.color_table.evaluations << self
    end
  end


  def validate_instance
    if !self.type.try(:suite?)
      errors.add_on_blank(:instance)
    end
  end

  def validate_suite
    if !(self.type.try(:suite?) || self.suite.blank?)
      errors.add(:suite, :not_nil)
    end
  end

  def validate_date
    if self.has_regular_suite?
      if self.date.blank?
        errors.add(:date, :blank)
      elsif !self.date_before_type_cast.is_a?(Date) && self.date_before_type_cast !~ /^\d{4}-\d{2}-\d{2}$/
        errors.add(:date, :invalid)
      end
    end
  end

  def validate_deleted_at
    unless !self.deleted_at || DateTime.parse(self.deleted_at.to_s)
      errors.add(:deleted_at, :invalid)
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
    if self.value_type == "grade" && self.value_aliases != GRADE_ALIASES
      self.value_aliases = GRADE_ALIASES
    elsif self.value_type == "boolean" && self.value_aliases != BOOLEAN_ALIASES
      self.value_aliases = BOOLEAN_ALIASES
    end
  end

  def persist_colors_and_stanines
    new_colors   = nil
    new_stanines = nil

    case self.value_type
    when "boolean"
      new_colors = { "0" => self.color_for_false.to_s, "1" => self.color_for_true.to_s } unless self.colors_changed?
    when "grade"
      unless self.colors_changed?
        new_colors = {
          "0" => self.color_for_grade_f,
          "1" => self.color_for_grade_e,
          "2" => self.color_for_grade_d,
          "3" => self.color_for_grade_c,
          "4" => self.color_for_grade_b,
          "5" => self.color_for_grade_a
        }
      end
      unless self.stanines_changed?
        new_stanines = {
          "0" => self.stanine_for_grade_f,
          "1" => self.stanine_for_grade_e,
          "2" => self.stanine_for_grade_d,
          "3" => self.stanine_for_grade_c,
          "4" => self.stanine_for_grade_b,
          "5" => self.stanine_for_grade_a
        }
      end
    when "numeric"
      unless self.colors_changed?
        colors = {}
        colors["red"]    = { "min" => self.red_min.to_i,    "max" => self.red_max.to_i }    if self.red_min    && self.red_max
        colors["yellow"] = { "min" => self.yellow_min.to_i, "max" => self.yellow_max.to_i } if self.yellow_min && self.yellow_max
        colors["green"]  = { "min" => self.green_min.to_i,  "max" => self.green_max.to_i }  if self.green_min  && self.green_max
        new_colors = !colors.blank? ? colors : nil
      end

      unless self.stanines_changed?
        stanines = {}

        stanines["1"] = {
          "min" => self.stanine1_min.to_i,
          "max" => self.stanine1_max.to_i
        } if self.stanine1_min && self.stanine1_max
        stanines["2"] = {
          "min" => self.stanine2_min.to_i,
          "max" => self.stanine2_max.to_i
        } if self.stanine2_min && self.stanine2_max
        stanines["3"] = {
          "min" => self.stanine3_min.to_i,
          "max" => self.stanine3_max.to_i
        } if self.stanine3_min && self.stanine3_max
        stanines["4"] = {
          "min" => self.stanine4_min.to_i,
          "max" => self.stanine4_max.to_i
        } if self.stanine4_min && self.stanine4_max
        stanines["5"] = {
          "min" => self.stanine5_min.to_i,
          "max" => self.stanine5_max.to_i
        } if self.stanine5_min && self.stanine5_max
        stanines["6"] = {
          "min" => self.stanine6_min.to_i,
          "max" => self.stanine6_max.to_i
        } if self.stanine6_min && self.stanine6_max
        stanines["7"] = {
          "min" => self.stanine7_min.to_i,
          "max" => self.stanine7_max.to_i
        } if self.stanine7_min && self.stanine7_max
        stanines["8"] = {
          "min" => self.stanine8_min.to_i,
          "max" => self.stanine8_max.to_i
        } if self.stanine8_min && self.stanine8_max
        stanines["9"] = {
          "min" => self.stanine9_min.to_i,
          "max" => self.stanine9_max.to_i
        } if self.stanine9_min && self.stanine9_max

        new_stanines = !stanines.blank? ? stanines : nil
      end
    end

    self.colors   = new_colors   if new_colors   && self.colors   != new_colors
    self.stanines = new_stanines if new_stanines && self.stanines != new_stanines
  end

  def parse_students_and_groups
    return unless defined?(@students_and_groups)

    if @students_and_groups.blank?
      self.evaluation_participants.clear
    else
      student_ids = []
      group_ids   = []

      @students_and_groups.split(",").each do |id|
        case id.strip
        when /g-(\d+)/
          group_ids << $1
        when /s-(\d+)/
          student_ids << $1
        end
      end

      participants = self.suite_participants.with_student_ids(student_ids).all +
        self.suite_participants.with_implicit_group_ids(group_ids)

      self.evaluation_participant_ids = participants.collect(&:id)
    end
  end

  def update_series_current!
    if (self.status_changed? || self.series_id_changed?) && self.series
      self.series.update_current!
    end
  end

  def create_series_from_name
    if self.type.try(:suite?) && self.series_id == 0
      series_name = self.series_name
      if !series_name.blank?
        series = Series.where([
          "suite_id = ? and name ilike ?",
          self.suite_id,
          series_name
        ]).first

        if series
          self.series_id = series.id
          self.series = series
        else
          self.create_series(name: series_name, suite_id: self.suite_id)
        end
      end
    end
  end

  def destroy_empty_series!
    if self.series_id_changed? && !self.series_id_was.nil? || self.destroyed?
      Series.where(id: self.series_id_was).first.try(:destroy_on_empty!)
    end
  end
end
