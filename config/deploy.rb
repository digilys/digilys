require "bundler/capistrano"

# Digilys is deployed to a single server. The name of the server
# can either be supplied as an environment variable +digilys_instance+
# when executing cap:
#
#   > digilys_instance=digilys-production cap deploy
#
# or it defaults to the server +digilys+.
#
# A good idea is to have an +~/.ssh/config+ which includes server details
# fo
set :digilys_server,   ENV["digilys_instance"] || "digilys"

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

before "deploy:finalize_update", "deploy:symlink_external_files"
before "deploy:finalize_update", "deploy:symlink_relative_public"
before "deploy:migrate",         "deploy:backup_db"

namespace :deploy do
  desc "Symlinks external files required for the app"
  task :symlink_external_files, roles: :app do
    run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{deploy_to}/shared/config/app_config.private.yml #{release_path}/config/app/base.private.yml"
  end

  desc "Symlinks the relative public directory, if any"
  task :symlink_relative_public, roles: :app do
    root_url = capture("echo -n $RAILS_RELATIVE_URL_ROOT")

    if root_url && !root_url.empty?
      root_dir = root_url.split("/")[0..-2].join("/")
      run "mkdir -p #{latest_release}/public#{root_dir}" if root_dir && !root_dir.empty?
      run "ln -nsf #{latest_release}/public #{latest_release}/public#{root_url}"
    end
  end

  desc "Invoke rake task"
  task :invoke do
    run "cd '#{current_path}' && #{rake} #{ENV['task']} RAILS_ENV=#{rails_env}"
  end

  task :backup_db, roles: :db do
    run "test -d #{deploy_to}/shared/backup || mkdir -p #{deploy_to}/shared/backup"
    db = YAML::load(capture("cat #{deploy_to}/shared/config/database.yml"))["production"]

    backup_file = "#{deploy_to}/shared/backup/#{db["database"]}.$(date +%Y%m%d%H%M%S).sql.gz"

    run "pg_dump -U #{db["username"]} #{db["database"]} | gzip > #{backup_file}"
  end
end
