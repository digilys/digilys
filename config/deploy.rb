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


role :web, digilys_server                # Your HTTP server, Apache/etc
role :app, digilys_server                # This may be the same as your `Web` server
role :db,  digilys_server, primary: true # This is where Rails migrations will run

# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,"tmp","restart.txt")}"
  end
end

before "deploy:finalize_update", "deploy:symlink_db"

namespace :deploy do
  desc "Symlinks the database.yml"
  task :symlink_db, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
  end
end
