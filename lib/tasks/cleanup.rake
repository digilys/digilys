# Tasks for cleaning data
namespace :app do
  namespace :cleanup do
    task unused_imported_groups: :environment do
      groups = Group.where(imported: true).where("id not in (select group_id from groups_students)").all

      groups.each { |g| puts "#{g.id}:\t#{g.name}" }

      puts "\nEnter 'yes' to destroy the unused groups, or 'no' to abort:"
      
      if get_input()
        puts "\nDestroying..."

        groups.collect(&:destroy)
      else
        puts "\nAborting..."
      end
    end
  end
end
