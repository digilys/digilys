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
    end

    desc "Export instances"
    task instances: :setup do
      puts "Exporting instances"
      @exporter.export_instances(File.open(File.join(ENV["output_dir"], "instances.json"), "w:ASCII-8BIT"))
    end
  end
end
