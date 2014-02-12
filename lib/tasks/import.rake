# Tasks for importing data
require "digilys/importer"
require "digilys/evaluation_template_importer"

namespace :app do
  namespace :import do

    task evaluation_templates_from_csv: :environment do

      csv = CSV.open(ENV["file"])

      importer = Digilys::EvaluationTemplateImporter.new(csv, ENV["instance_id"], ENV["update"])

      if !importer.valid?
        puts "Invalid rows:\n"
        importer.invalid.each { |d| puts d[:original_row].to_json + "\n" + d[:model].errors.to_json + "\n\n" }
      end

      puts "\nTotal: #{importer.valid_count + importer.invalid_count}, to be updated: #{importer.update_count}" if ENV["update"]

      puts "\nEnter 'yes' to import #{importer.valid_count} valid rows, or 'no' to abort:"

      if get_input()
        puts "\nImporting..."
        importer.import!
      else
        puts "\nAborting..."
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
          school:      row[0].try(:strip),
          grade:       row[1].try(:strip),
          personal_id: row[2].try(:strip),
          last_name:   row[3].try(:strip),
          first_name:  row[4].try(:strip),
          gender:      parse_gender(row[5].try(:strip))
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

        student.first_name  = attributes[:first_name]
        student.last_name   = attributes[:last_name]
        student.gender      = attributes[:gender]

        student.instance_id = ENV["instance_id"]

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
          school_name = d[:attributes][:school]
          grade_name  = d[:attributes][:grade]
          student     = d[:model]
          school      = nil
          grade       = nil

          unless school_name.blank?
            school = Group.where([ "name ilike ?", school_name ]).first_or_create!(
              imported: true,
              name: school_name,
              instance_id: ENV["instance_id"]
            )
          end

          unless grade_name.blank?
            grade = school.children.where([ "name ilike ?", grade_name ]).first_or_create!(
              imported: true,
              name: grade_name,
              instance_id: ENV["instance_id"]
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
      else
        puts "\nAborting..."
      end
    end

    def parse_gender(str)
      case str.try(:downcase)
      when "flicka", "f", "kvinna", "k"
        :female
      when "pojke", "f", "man", "m"
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


    desc "Import setup"
    task setup: :environment do
      raise "Environment variable export_dir is required" if !ENV.has_key?("export_dir") || !File.directory?(ENV["export_dir"])

      puts "Importing data from: #{ENV["export_dir"]}\n"

      @importer = Digilys::Importer.new(ENV["id_prefix"] || "export")

      # Load any existing mappings
      @mappings_file = File.join(ENV["export_dir"], "import-mappings.json")

      if File.file?(@mappings_file)
        parser = Yajl::Parser.new(symbolize_keys: false)
        @importer.mappings = parser.parse(File.open(@mappings_file, "r"))
      end

      # Add the mapping persistence after all running tasks
      # (simulating something like after_tasks()
      # http://stackoverflow.com/questions/1689504/how-do-i-make-a-rake-task-run-after-all-other-tasks-i-e-a-rake-afterbuild-tas#comment23711800_1767205
      Rake.application.top_level_tasks << "app:import:persist_mappings"
    end

    task persist_mappings: :setup do
      puts "Persisting mappings to #{@mappings_file}"

      encoder = Yajl::Encoder.new(pretty: true)
      encoder.encode(@importer.mappings, File.open(@mappings_file, "w"))
    end

    desc "Import all data"
    task all: :setup do
      Rake::Task["app:import:instances"].invoke
      Rake::Task["app:import:users"].invoke
      Rake::Task["app:import:students"].invoke
      Rake::Task["app:import:groups"].invoke
      Rake::Task["app:import:instructions"].invoke
      Rake::Task["app:import:suites"].invoke
      Rake::Task["app:import:participants"].invoke
      Rake::Task["app:import:meetings"].invoke
      Rake::Task["app:import:activities"].invoke
      Rake::Task["app:import:generic_evaluations"].invoke
      Rake::Task["app:import:evaluation_templates"].invoke
      Rake::Task["app:import:suite_evaluations"].invoke
      Rake::Task["app:import:results"].invoke
      Rake::Task["app:import:settings"].invoke
      Rake::Task["app:import:table_states"].invoke
      Rake::Task["app:import:roles"].invoke
    end

    desc "Import instances"
    task instances: :setup do
      file = File.join(ENV["export_dir"], "instances.json")

      if File.file?(file)
        puts "Importing instances from #{file}"
        @importer.import_instances(File.open(file, "r"))
      else
        puts "Export file not found: instances.json"
      end
    end

    desc "Import users"
    task users: :setup do
      file = File.join(ENV["export_dir"], "users.json")

      if File.file?(file)
        puts "Importing users from #{file}"
        @importer.import_users(File.open(file, "r"))
      else
        puts "Export file not found: users.json"
      end
    end

    desc "Import students"
    task students: :setup do
      file = File.join(ENV["export_dir"], "students.json")

      if File.file?(file)
        puts "Importing students from #{file}"
        @importer.import_students(File.open(file, "r"))
      else
        puts "Export file not found: students.json"
      end
    end

    desc "Import groups"
    task groups: :setup do
      file = File.join(ENV["export_dir"], "groups.json")

      if File.file?(file)
        puts "Importing groups from #{file}"
        @importer.import_groups(File.open(file, "r"))
      else
        puts "Export file not found: groups.json"
      end
    end

    desc "Import instructions"
    task instructions: :setup do
      file = File.join(ENV["export_dir"], "instructions.json")

      if File.file?(file)
        puts "Importing instructions from #{file}"
        @importer.import_instructions(File.open(file, "r"))
      else
        puts "Export file not found: instructions.json"
      end
    end

    desc "Import suites"
    task suites: :setup do
      file = File.join(ENV["export_dir"], "suites.json")

      if File.file?(file)
        puts "Importing suites from #{file}"
        @importer.import_suites(File.open(file, "r"))
      else
        puts "Export file not found: suites.json"
      end
    end

    desc "Import participants"
    task participants: :setup do
      file = File.join(ENV["export_dir"], "participants.json")

      if File.file?(file)
        puts "Importing participants from #{file}"
        @importer.import_participants(File.open(file, "r"))
      else
        puts "Export file not found: participants.json"
      end
    end

    desc "Import meetings"
    task meetings: :setup do
      file = File.join(ENV["export_dir"], "meetings.json")

      if File.file?(file)
        puts "Importing meetings from #{file}"
        @importer.import_meetings(File.open(file, "r"))
      else
        puts "Export file not found: meetings.json"
      end
    end

    desc "Import activities"
    task activities: :setup do
      file = File.join(ENV["export_dir"], "activities.json")

      if File.file?(file)
        puts "Importing activities from #{file}"
        @importer.import_activities(File.open(file, "r"))
      else
        puts "Export file not found: activities.json"
      end
    end

    desc "Import generic_evaluations"
    task generic_evaluations: :setup do
      file = File.join(ENV["export_dir"], "generic_evaluations.json")

      if File.file?(file)
        puts "Importing generic_evaluations from #{file}"
        @importer.import_generic_evaluations(File.open(file, "r"))
      else
        puts "Export file not found: generic_evaluations.json"
      end
    end

    desc "Import evaluation_templates"
    task evaluation_templates: :setup do
      file = File.join(ENV["export_dir"], "evaluation_templates.json")

      if File.file?(file)
        puts "Importing evaluation_templates from #{file}"
        @importer.import_evaluation_templates(File.open(file, "r"))
      else
        puts "Export file not found: evaluation_templates.json"
      end
    end

    desc "Import suite_evaluations"
    task suite_evaluations: :setup do
      file = File.join(ENV["export_dir"], "suite_evaluations.json")

      if File.file?(file)
        puts "Importing suite_evaluations from #{file}"
        @importer.import_suite_evaluations(File.open(file, "r"))
      else
        puts "Export file not found: suite_evaluations.json"
      end
    end

    desc "Import results"
    task results: :setup do
      file = File.join(ENV["export_dir"], "results.json")

      if File.file?(file)
        puts "Importing results from #{file}"
        @importer.import_results(File.open(file, "r"))
      else
        puts "Export file not found: results.json"
      end
    end

    desc "Import settings"
    task settings: :setup do
      file = File.join(ENV["export_dir"], "settings.json")

      if File.file?(file)
        puts "Importing settings from #{file}"
        @importer.import_settings(File.open(file, "r"))
      else
        puts "Export file not found: settings.json"
      end
    end

    desc "Import table_states"
    task table_states: :setup do
      file = File.join(ENV["export_dir"], "table_states.json")

      if File.file?(file)
        puts "Importing table_states from #{file}"
        @importer.import_table_states(File.open(file, "r"))
      else
        puts "Export file not found: table_states.json"
      end
    end

    desc "Import roles"
    task roles: :setup do
      file = File.join(ENV["export_dir"], "roles.json")

      if File.file?(file)
        puts "Importing roles from #{file}"
        @importer.import_roles(File.open(file, "r"))
      else
        puts "Export file not found: roles.json"
      end
    end
  end
end
