# Application bootstrapping tasks
namespace :app do

  desc "Perform all bootstrap tasks"
  task :bootstrap do
    %w(
    create_roles
    create_instance
    ).each do |task|
      Rake::Task["app:bootstrap:#{task}"].invoke
    end
  end

  namespace :bootstrap do
    task create_roles: :environment do
      puts "Creating roles"

      puts Role.where(name: "admin").first_or_create.name
      puts Role.where(name: "planner").first_or_create.name
    end

    task create_instance: :environment do
      puts "Creating base instance"
      puts Instance.where(name:"root").first_or_create.name
    end
  end
end
