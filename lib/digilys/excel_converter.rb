require "csv"

module Digilys::ExcelConverter
  def convert_student_data_file(source_file_name, target_file_name, source_file_extension = nil)
    source_file_extension ||= File.extname(source_file_name)
    source = Roo::Spreadsheet.open(source_file_name, extension: source_file_extension)

    CSV.open(target_file_name, "wb", col_sep: "\t") do |tsv|
      source.each do |row|
        tsv << [
          row[0],
          parse_grade(row[1]),
          parse_person_id(row[2]),
          row[3],
          row[4],
          row[5]
        ]
      end
    end
  end

  module_function :convert_student_data_file
  public          :convert_student_data_file


  private

  def parse_grade(raw)
    case raw
    when Float then raw.to_i
    else
      raw
    end
  end

  module_function :parse_grade

  def parse_person_id(raw)
    return raw unless raw.is_a?(Float)

    s = raw.to_i.to_s

    birth_date = s[0..-5].rjust(6, "0")
    last_four  = s[-4, 4]

    return "#{birth_date}-#{last_four}"
  end

  module_function :parse_person_id
end
