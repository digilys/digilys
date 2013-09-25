# Application utility tasks
namespace :app do

  desc "Grant admin role to a user"
  task grant_admin: :environment do
    puts "Enter the email address of the user: "

    STDOUT.flush
    email = STDIN.gets.chomp

    user = User.where(email: email).first

    if user.blank?
      puts "User not found!"
    else
      puts "User found: #{user.name}, #{user.email}"
      puts "Granting admin role..."

      user.add_role :admin

      puts "Done!"
    end
  end

  desc "Creates an admin user"
  task create_admin: :environment do
    puts "Creating admin user"

    admin = User.new do |u|
      u.name                  = "Admin"
      u.email                 = "admin@example.com"
      u.password              = "adminadmin"
      u.password_confirmation = "adminadmin"
      u.active_instance       = Instance.order("id asc").first
    end

    admin.save!
    admin.add_role :admin

    puts "Admin user created: #{admin.email}, password 'adminadmin'"
  end
end
