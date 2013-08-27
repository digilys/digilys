# Tasks for importing data
namespace :app do
  namespace :import do

    task evaluation_templates_from_csv: :environment do
      title = true

      data = []
      CSV.foreach(ENV["file"]) do |row|
        # Skip first row
        if title
          title = false
          next
        end

        max_result = row[3].to_i

        red, yellow, green = parse_color_intervals(row[4], row[5], row[6], max_result)

        attributes = {
          name:          row[0].try(:gsub, "\u00A0", " "),
          description:   row[1].try(:gsub, "\u00A0", " "),
          category_list: row[2].try(:gsub, "\u00A0", " "),
          max_result:    max_result,
          red:           red,
          yellow:        yellow,
          green:         green,
          stanine1:      parse_interval(row[7],  max_result),
          stanine2:      parse_interval(row[8],  max_result),
          stanine3:      parse_interval(row[9],  max_result),
          stanine4:      parse_interval(row[10], max_result),
          stanine5:      parse_interval(row[11], max_result),
          stanine6:      parse_interval(row[12], max_result),
          stanine7:      parse_interval(row[13], max_result),
          stanine8:      parse_interval(row[14], max_result),
          stanine9:      parse_interval(row[15], max_result)
        }

        data << {
          original_row: row,
          attributes:   attributes
        }
      end

      valid   = []
      invalid = []

      data.each do |d|
        attributes = d[:attributes]
        evaluation = Evaluation.new

        evaluation.value_type    = :numeric
        evaluation.target        = :all
        evaluation.type          = :template

        evaluation.name          = attributes[:name]
        evaluation.description   = attributes[:description]
        evaluation.category_list = attributes[:category_list]
        evaluation.max_result    = attributes[:max_result]

        evaluation.red_min       = attributes[:red].try(:min)
        evaluation.red_max       = attributes[:red].try(:max)
        evaluation.yellow_min    = attributes[:yellow].try(:min)
        evaluation.yellow_max    = attributes[:yellow].try(:max)
        evaluation.green_min     = attributes[:green].try(:min)
        evaluation.green_max     = attributes[:green].try(:max)

        evaluation.stanine1_min  = attributes[:stanine1].try(:min)
        evaluation.stanine1_max  = attributes[:stanine1].try(:max)
        evaluation.stanine2_min  = attributes[:stanine2].try(:min)
        evaluation.stanine2_max  = attributes[:stanine2].try(:max)
        evaluation.stanine3_min  = attributes[:stanine3].try(:min)
        evaluation.stanine3_max  = attributes[:stanine3].try(:max)
        evaluation.stanine4_min  = attributes[:stanine4].try(:min)
        evaluation.stanine4_max  = attributes[:stanine4].try(:max)
        evaluation.stanine5_min  = attributes[:stanine5].try(:min)
        evaluation.stanine5_max  = attributes[:stanine5].try(:max)
        evaluation.stanine6_min  = attributes[:stanine6].try(:min)
        evaluation.stanine6_max  = attributes[:stanine6].try(:max)
        evaluation.stanine7_min  = attributes[:stanine7].try(:min)
        evaluation.stanine7_max  = attributes[:stanine7].try(:max)
        evaluation.stanine8_min  = attributes[:stanine8].try(:min)
        evaluation.stanine8_max  = attributes[:stanine8].try(:max)
        evaluation.stanine9_min  = attributes[:stanine9].try(:min)
        evaluation.stanine9_max  = attributes[:stanine9].try(:max)

        if evaluation.valid?
          valid << evaluation
        else
          invalid << d.merge(model: evaluation)
        end
      end

      if !invalid.blank?
        puts "Invalid rows:\n"
        invalid.each { |d| puts d[:original_row].to_json + "\n" + d[:model].errors.to_json + "\n\n" }
      end

      puts "\nEnter 'yes' to import #{valid.length} valid rows, or 'no' to abort:"

      if get_input()
        puts "\nImporting..."

        valid.collect(&:save!)

        puts "\nNew ids:"
        puts valid.collect(&:id).join(",")
      else
        puts "\nAborting..."
      end
    end

    def parse_color_intervals(red_str, yellow_str, green_str, max_result)
      red    = parse_interval(red_str,    max_result)
      yellow = parse_interval(yellow_str, max_result)
      green  = parse_interval(green_str,  max_result)

      return nil if red.nil? && yellow.nil? && green.nil?

      if yellow_str.include?("%")
        yellow_min = ((yellow.min.to_f / 100.0) * max_result.to_f).ceil
        yellow_max = ((yellow.max.to_f / 100.0) * max_result.to_f).floor

        yellow = yellow_min..yellow_max

        if green.max < yellow.min || red.min > yellow.max
          # Reverse order
          green = 0..(yellow_min - 1)
          red   = (yellow_max + 1)..max_result
        else
          # Normal order
          red   = 0..(yellow_min - 1)
          green = (yellow_max + 1)..max_result
        end
      end

      return red, yellow, green
    end

    def parse_interval(str, max_result)
      if str =~ /-/
        from, to = str.split("-")

        from     = from.to_i
        to       = to.to_i
        to       = max_result if to == 0 && from > 0

        return from..to
      elsif str =~ /\d+/
        return (str.to_i)..(str.to_i)
      else
        return nil
      end
    end

    task students_and_groups_from_tsv: :environment do
      title = true
      data = []

      CSV.foreach(ENV["file"], col_sep: "\t") do |row|
        # Skip first row
        if title
          title = false
          next
        end

        attributes = {
          school:      row[0].strip,
          grade:       row[1].strip,
          personal_id: row[2].strip,
          first_name:  row[3].strip,
          last_name:   row[4].strip,
          gender:      parse_gender(row[5].strip)
        }

        data << {
          original_row: row,
          attributes:   attributes
        }
      end

      valid   = []
      invalid = []

      data.each do |d|
        attributes = d[:attributes]

        student = Student.where(personal_id: attributes[:personal_id]).first_or_initialize()

        student.first_name = attributes[:first_name]
        student.last_name  = attributes[:last_name]
        student.gender     = attributes[:gender]

        if student.valid?
          valid << d.merge(model: student)
        else
          invalid << d.merge(model: student)
        end
      end

      if !invalid.blank?
        puts "Invalid rows:\n"
        invalid.each { |d| puts d[:original_row].to_json + "\n" + d[:model].errors.to_json + "\n\n" }
      end

      puts "\nEnter 'yes' to import #{valid.length} valid rows, or 'no' to abort:"
      
      if get_input()
        puts "\nImporting..."

        valid.each do |d|
          school  = Group.where(name: d[:attributes][:school]).first_or_create!(imported: true)
          grade   = school.children.where(name: d[:attributes][:grade]).first_or_create!(imported: true)
          student = d[:model]

          student.save!

          grade.add_students(student)
        end
      else
        puts "\nAborting..."
      end
    end

    def parse_gender(str)
      case str.to_i
      when "flicka"
        :female
      when "pojke"
        :male
      else
        nil
      end
    end

    def get_input
      STDOUT.flush
      input = STDIN.gets.chomp
      case input.downcase
      when "yes"
        return true
      when "no"
        return false
      else
        puts "You must enter 'yes' or 'no'"
        return get_input
      end
    end 
  end
end
