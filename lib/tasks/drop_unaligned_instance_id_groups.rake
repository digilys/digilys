# Run like: rake drop_unaligned_instance_id_groups

namespace :fix do
  desc "Delete groups where instance_id differs from that of parent"

  task drop_unaligned_instance_id_groups: :environment do
    Group.all.each do |g|
      if g.parent && g.instance_id != g.parent.instance_id
        g.destroy
      end
    end
    puts "Done!"
  end

end
