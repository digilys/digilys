# Application bootstrapping tasks
namespace :app do

  desc "Perform all bootstrap tasks"
  task :bootstrap do
    %w(
    create_admin_account
    ).each do |task|
      Rake::Task["app:bootstrap:#{task}"].invoke
    end
  end

  namespace :bootstrap do
    task create_admin_account: :environment do
      puts "Creating admin account"

      admin = User.with_role(:admin).first

      if admin
        puts "Admin user alread exists: #{admin.email}"
      else
        admin = User.new do |u|
          u.email = "admin@example.com"
          u.password = "adminadmin"
          u.password_confirmation = "adminadmin"
        end

        admin.save!
        admin.add_role :admin

        puts "Admin user created: #{admin.email}, password 'adminadmin'"
      end
    end
  end
end
