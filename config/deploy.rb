require "bundler/capistrano"

# Digilys is deployed to a single server. The name of the server
# can either be supplied as an environment variable +digilys_instance+
# when executing cap:
#
#   > digilys_instance=digilys-production-alternative cap deploy
#
# or it defaults to the server +digilys_instance+.
#
# A good idea is to have an +~/.ssh/config+ which includes server details
# fo
set :digilys_server,   ENV["digilys_instance"] || "digilys-production"

set :application,      "digilys"
set :scm,              :git
set :use_sudo,         false

# Local deployment
set :repository,       "."
set :local_repository, "."
set :deploy_via,       :copy

set :deploy_to,        -> { capture("echo -n $HOME/app") }

set :passenger_port,   -> { capture("cat #{deploy_to}/shared/config/passenger_port.txt || echo 24500").to_i }

role :web, digilys_server                # Your HTTP server, Apache/etc
role :app, digilys_server                # This may be the same as your `Web` server
role :db,  digilys_server, primary: true # This is where Rails migrations will run

# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start, roles: :app do
    run "cd -- #{deploy_to}/current && bundle exec passenger start #{deploy_to}/current -p #{passenger_port} -e #{rails_env} -d --log-file #{deploy_to}/shared/log/passenger.log --pid-file #{deploy_to}/shared/pids/passenger.pid"
  end
  task :stop, roles: :app do
    run "cd -- #{deploy_to}/current && bundle exec passenger stop #{deploy_to}/current -p #{passenger_port} --pid-file #{deploy_to}/shared/pids/passenger.pid"
  end
  task :restart, roles: :app, except: { no_release: true } do
    run "touch #{File.join(current_path,"tmp","restart.txt")}"
  end
end

before "deploy:finalize_update", "deploy:symlink_db"

namespace :deploy do
  desc "Symlinks the database.yml"
  task :symlink_db, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
  end
end
