class Digilys::ResultImporter
  def initialize(csv, evaluation_id, has_header_row = false)
    @evaluation_id = evaluation_id
    @evaluation = Evaluation.find(evaluation_id)
    @has_header_row  = has_header_row

    @parsed_attributes = []
    @valid             = []
    @invalid_results   = []
    @invalid_students  = []
    @old_values        = {}
    @update_count      = 0


    csv.each do |row|
      # Skip first row if it's a title row
      if @has_header_row
        @has_header_row = false
        next
      end

      attributes = {
        personal_id:   row[0].try(:strip),
        result:        row[1].try(:strip)
      }

      @parsed_attributes << {
        original_row: row,
        attributes:   attributes
      }
    end
  ensure
    csv.close
  end

  attr_reader :parsed_attributes

  def valid?
    return @invalid_results.blank? && @invalid_students.blank? unless @valid.blank? && @invalid_results.blank? && @invalid_results.blank?

    @parsed_attributes.each do |parsed_attrs|
      attributes = parsed_attrs[:attributes]

      student = Student.find_by_personal_id(attributes[:personal_id].to_s)
      participant ||= @evaluation.participants.find_by_student_id(student.id) unless student.nil?
      if !participant.nil?
        update_result(participant, parsed_attrs)
      else
        @invalid_students << attributes[:personal_id]
      end
    end


    return @invalid_results.blank? && @invalid_students.blank?
  end

  def valid_count
    @valid.length
  end
  def invalid_results_count
    @invalid_results.length
  end
  def invalid_students_count
    @invalid_students.length
  end
  attr_reader :update_count

  attr_reader :valid, :invalid_results, :invalid_students, :old_values

  def import!
    @valid.collect { |d| d[:model].save! } if valid?
  end

  private
    def update_result(participant, parsed_attributes)
      attributes = parsed_attributes[:attributes]

      if result = @evaluation.results.detect { |r| r.student_id == participant.student_id }
        @old_values[result.id] = result.value unless result.value == attributes[:result].to_i
        result.update_attributes({:value => attributes[:result]})
      else
        result = @evaluation.results.create(student_id: participant.student_id, value: attributes[:result])
      end

      if result.valid?
        @valid << parsed_attributes.merge(model: result)
      else
        @invalid_results << parsed_attributes.merge(model: result)
      end

      @update_count += 1 unless result.new_record?
    end

end
