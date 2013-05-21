class Student < ActiveRecord::Base
  extend Enumerize

  has_many :participants, dependent: :destroy
  has_many :suites,       through: :participants
  has_many :results,      dependent: :destroy
  has_many :evaluations,  through: :results

  has_and_belongs_to_many :groups

  attr_accessible :personal_id,
    :first_name,
    :last_name,
    :gender,
    :data,
    :data_text

  validates :personal_id, presence: true, uniqueness: true
  validates :first_name,  presence: true
  validates :last_name,   presence: true

  enumerize :gender, in: [ :male, :female ]


  serialize   :data, JSON
  validate    :validate_data_text
  before_save :convert_data_text_to_data

  def name
    "#{self.first_name} #{self.last_name}"
  end
  def name_was
    "#{self.first_name_was} #{self.last_name_was}"
  end

  def data_text
    if !@data_text && !self.data.blank?
      @data_text = self.data.collect { |key, value| "#{key}: #{json_value_to_text_value(value)}" }.join("\n")
    end
    return @data_text
  end
  def data_text=(value)
    @data_text = value
  end

  # Add this user to all of the groups, and all of the group's parents
  def add_to_groups(groups)
    return if groups.blank?

    groups = Group.find(groups.split(/\s*,\s*/)) if groups.is_a? String

    [*groups].each do |group|
      group.add_students(self)
    end
  end

  # Removes this user to all of the groups, and all of the group's parents
  def remove_from_groups(groups)
    return if groups.blank?

    [*groups].each do |g|
      group = g.is_a?(Group) ? g : Group.find(g)
      group.remove_students(self)
    end
  end


  private

  def validate_data_text
    data_text = self.data_text
    return if data_text.blank?

    line_num = 1
    faulty_lines = []

    data_text.each_line do |line|
      faulty_lines << line_num if !line.blank? && line.count(":") != 1
      line_num += 1
    end

    errors.add(:data_text, :faulty_lines, lines: faulty_lines.join(",")) unless faulty_lines.blank?
  end

  def convert_data_text_to_data
    data_text = self.data_text
    return if data_text.blank?

    data = {}

    data_text.each_line do |line|
      next if line.blank?

      key, value = line.split(":").collect(&:strip)
      data[key] = text_value_to_json_value(value)
    end

    self.data = data
  end

  def json_value_to_text_value(value)
    case value
    when Numeric
      value.to_s.gsub(".", ",")
    when true
      "Ja"
    when false
      "Nej"
    else
      value.to_s
    end
  end

  def text_value_to_json_value(value)
    maybe_numeric = value.gsub(",", ".").gsub(/\s/, "")

    case maybe_numeric
    when /^[+-]?\d+.\d*$/ # Float
      return maybe_numeric.to_f
    when /^[+-]?\d+$/ # Int
      return maybe_numeric.to_i
    end

    stripped = value.strip

    case stripped
    when /^(ja|yes|sant|true)$/i
      return true
    when /^(nej|no|falskt|false)$/i
      return false
    end

    return value
  end
end
