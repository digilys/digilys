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
  end
end
