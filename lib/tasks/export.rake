# Tasks for exporting data
require "digilys/exporter"

namespace :app do
  namespace :export do
    desc "Export setup"
    task setup: :environment do
      ENV["output_dir"] ||= "tmp/export/#{Time.now.strftime("%Y%m%d%H%M%S")}"
      puts "Exporting data to: #{ENV["output_dir"]}\n"
      FileUtils.makedirs(File.join(Rails.root, ENV["output_dir"]))

      @exporter = Digilys::Exporter.new(ENV["id_prefix"] || "export")
    end

    desc "Export all data"
    task all: :setup do
      Rake::Task["app:export:instances"].invoke
      Rake::Task["app:export:users"].invoke
      Rake::Task["app:export:students"].invoke
      Rake::Task["app:export:groups"].invoke
      Rake::Task["app:export:instructions"].invoke
      Rake::Task["app:export:suites"].invoke
      Rake::Task["app:export:participants"].invoke
      Rake::Task["app:export:meetings"].invoke
      Rake::Task["app:export:activities"].invoke
      Rake::Task["app:export:generic_evaluations"].invoke
      Rake::Task["app:export:evaluation_templates"].invoke
      Rake::Task["app:export:suite_evaluations"].invoke
      Rake::Task["app:export:results"].invoke
      Rake::Task["app:export:settings"].invoke
      Rake::Task["app:export:table_states"].invoke
      Rake::Task["app:export:roles"].invoke
    end

    desc "Export instances"
    task instances: :setup do
      puts "Exporting instances"
      @exporter.export_instances(File.open(File.join(ENV["output_dir"], "instances.json"), "w:ASCII-8BIT"))
    end

    desc "Export users"
    task users: :setup do
      puts "Exporting users"
      @exporter.export_users(File.open(File.join(ENV["output_dir"], "users.json"), "w:ASCII-8BIT"))
    end

    desc "Export students"
    task students: :setup do
      puts "Exporting students"
      @exporter.export_students(File.open(File.join(ENV["output_dir"], "students.json"), "w:ASCII-8BIT"))
    end

    desc "Export groups"
    task groups: :setup do
      puts "Exporting groups"
      @exporter.export_groups(File.open(File.join(ENV["output_dir"], "groups.json"), "w:ASCII-8BIT"))
    end

    desc "Export instructions"
    task instructions: :setup do
      puts "Exporting instructions"
      @exporter.export_instructions(File.open(File.join(ENV["output_dir"], "instructions.json"), "w:ASCII-8BIT"))
    end

    desc "Export suites"
    task suites: :setup do
      puts "Exporting suites"
      @exporter.export_suites(File.open(File.join(ENV["output_dir"], "suites.json"), "w:ASCII-8BIT"))
    end

    desc "Export participants"
    task participants: :setup do
      puts "Exporting participants"
      @exporter.export_participants(File.open(File.join(ENV["output_dir"], "participants.json"), "w:ASCII-8BIT"))
    end

    desc "Export meetings"
    task meetings: :setup do
      puts "Exporting meetings"
      @exporter.export_meetings(File.open(File.join(ENV["output_dir"], "meetings.json"), "w:ASCII-8BIT"))
    end

    desc "Export activities"
    task activities: :setup do
      puts "Exporting activities"
      @exporter.export_activities(File.open(File.join(ENV["output_dir"], "activities.json"), "w:ASCII-8BIT"))
    end

    desc "Export generic_evaluations"
    task generic_evaluations: :setup do
      puts "Exporting generic_evaluations"
      @exporter.export_generic_evaluations(File.open(File.join(ENV["output_dir"], "generic_evaluations.json"), "w:ASCII-8BIT"))
    end

    desc "Export evaluation_templates"
    task evaluation_templates: :setup do
      puts "Exporting evaluation_templates"
      @exporter.export_evaluation_templates(File.open(File.join(ENV["output_dir"], "evaluation_templates.json"), "w:ASCII-8BIT"))
    end

    desc "Export suite_evaluations"
    task suite_evaluations: :setup do
      puts "Exporting suite_evaluations"
      @exporter.export_suite_evaluations(File.open(File.join(ENV["output_dir"], "suite_evaluations.json"), "w:ASCII-8BIT"))
    end

    desc "Export results"
    task results: :setup do
      puts "Exporting results"
      @exporter.export_results(File.open(File.join(ENV["output_dir"], "results.json"), "w:ASCII-8BIT"))
    end

    desc "Export settings"
    task settings: :setup do
      puts "Exporting settings"
      @exporter.export_settings(File.open(File.join(ENV["output_dir"], "settings.json"), "w:ASCII-8BIT"))
    end

    desc "Export table_states"
    task table_states: :setup do
      puts "Exporting table_states"
      @exporter.export_table_states(File.open(File.join(ENV["output_dir"], "table_states.json"), "w:ASCII-8BIT"))
    end

    desc "Export roles"
    task roles: :setup do
      puts "Exporting roles"
      @exporter.export_roles(File.open(File.join(ENV["output_dir"], "roles.json"), "w:ASCII-8BIT"))
    end
  end
end
