require "bundler/capistrano"

set :application,      "digilys"
set :scm,              :git
set :use_sudo,         false

# Local deployment
set :repository,       "."
set :local_repository, "."
set :deploy_via,       :copy

set :deploy_to,        "/home/digilys/app"


# As of now, deploying requires you to have the following virtual hosts
# setup in your ~/.ssh/config:
#
# - digilys-production
#
# The server"s different roles can be seen below
role :web, "digilys-production"                # Your HTTP server, Apache/etc
role :app, "digilys-production"                # This may be the same as your `Web` server
role :db,  "digilys-production", primary: true # This is where Rails migrations will run

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
