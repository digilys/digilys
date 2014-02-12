class Digilys::StudentDataImporter
  def initialize(tsv, instance_id, has_header_row = true)
    @instance_id       = instance_id
    @has_header_row    = has_header_row

    @parsed_attributes = []
    @valid             = []
    @invalid           = []

    tsv.each do |row|
      # Skip first row
      if @has_header_row
        @has_header_row = false
        next
      end

      attributes = {
        school:      row[0].try(:strip),
        grade:       row[1].try(:strip),
        personal_id: row[2].try(:strip),
        last_name:   row[3].try(:strip),
        first_name:  row[4].try(:strip),
        gender:      parse_gender(row[5].try(:strip))
      }

      @parsed_attributes << {
        original_row: row,
        attributes:   attributes
      }
    end
  end

  attr_reader :parsed_attributes

  def valid?
    return @invalid.blank? unless @invalid.blank? && @valid.blank?

    @parsed_attributes.each do |d|
      attributes = d[:attributes]

      student = Student.where(personal_id: attributes[:personal_id]).first_or_initialize()

      student.first_name  = attributes[:first_name]
      student.last_name   = attributes[:last_name]
      student.gender      = attributes[:gender]

      student.instance_id = @instance_id

      if student.valid?
        @valid << d.merge(model: student)
      else
        @invalid << d.merge(model: student)
      end
    end

    return @invalid.blank?
  end

  def valid_count
    @valid.length
  end
  def invalid_count
    @invalid.length
  end

  attr_reader :invalid

  def import!
    return false unless valid?


    @valid.each do |d|
      school_name = d[:attributes][:school]
      grade_name  = d[:attributes][:grade]
      student     = d[:model]
      school      = nil
      grade       = nil

      unless school_name.blank?
        school = Group.where([ "name ilike ?", school_name ]).first_or_create!(
          imported: true,
          name: school_name,
          instance_id: @instance_id
        )
      end

      unless grade_name.blank?
        grade = school.children.where([ "name ilike ?", grade_name ]).first_or_create!(
          imported: true,
          name: grade_name,
          instance_id: @instance_id
        )

        grade.parent(true)
      end

      student.save!

      if grade
        grade.add_students(student)
      elsif school
        school.add_students(student)
      end
    end
  end


  private

  def parse_gender(str)
    case str.try(:downcase)
    when "flicka", "f", "kvinna", "k"
      :female
    when "pojke", "p", "man", "m"
      :male
    else
      nil
    end
  end
end
