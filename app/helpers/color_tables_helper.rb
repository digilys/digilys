module ColorTablesHelper
  def color_table_columns(student_data, evaluations)
    columns = [
      {
        id:       "student-name",
        name:     Student.human_attribute_name(:name),
        field:    "name"
      }.to_json
    ]
    columns += student_data_columns(student_data) || []
    columns += evaluation_columns(evaluations) || []
    columns.join(",")
  end

  def student_data_columns(student_data)
    return nil if student_data.blank?

    student_data.collect do |key|
      {
        id:       "student-data-#{key.parameterize}",
        name:     key,
        field:    "student_data_#{key.parameterize("_")}"
      }.to_json
    end
  end

  def evaluation_columns(evaluations)
    return nil if evaluations.blank?

    evaluations.collect do |evaluation|
      {
        id:       "evaluation-#{evaluation.id}",
        name:     evaluation.name,
        field:    "evaluation_#{evaluation.id}"
      }.to_json
    end
  end

  def result_rows(students, student_data, evaluations)
    return [] if students.blank?

    values = {}

    rows = students.collect do |student|
      s = {
        id:   student.id,
        name: student.name
      }

      student_data.each do |key|
        s["student_data_#{key.parameterize("_")}"] = student.data_humanized[key]
      end

      evaluations.each do |evaluation|
        next unless result = evaluation.result_for(student)

        if result.value
          values[evaluation.id] ||= []
          values[evaluation.id] << result.value
        end

        s["evaluation_#{evaluation.id}"] = result.display_value
      end

      s.to_json
    end

    averages = {
      id: 0,
      name: t(:"color_tables.averages"),
    }

    values.each do |evaluation_id, values|
      averages["evaluation_#{evaluation_id}"] = values.instance_eval { reduce(:+).to_f / size }.round(2)
    end

    rows << averages.to_json

    return rows
  end
end
