# For all users supplied as parameter: If admin revoke to planner
# Run like: rake app:revoke_admin_to_planner user1@example.org,user2@example.org,...

namespace :fix do
  desc "Revoke admin(s) to planner(s)"

  task revoke_admin_to_planner: :environment do
    users = ARGV[1]
    if !users
      puts "Usage: rake app:revoke_admin_to_planner user1@exapmle.org,user2@eaxample.org,..."
    else
      users.gsub(/ /, "").gsub(/"/, "").split(',').each do |email|
        u = User.find_by_email(email)
        if u && u.has_role?(:admin)
          u.add_role(:planner)
          u.remove_role(:admin)
          u.save!
        end
      end
      puts "Done!"
    end
  end

end
