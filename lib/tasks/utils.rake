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
end
