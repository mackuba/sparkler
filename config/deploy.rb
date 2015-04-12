require 'bundler/capistrano'

set :application, "sparkle"
set :repository, "git@github.com:jsuder/sparkler.git"
set :scm, :git
set :keep_releases, 5
set :use_sudo, false
set :deploy_to, "/var/www/sparkle"
set :deploy_via, :remote_cache
set :migrate_env, "RACK_ENV=production"

server "matterhorn", :app, :web, :db, :primary => true

after 'deploy:update_code', 'deploy:link_configs'

after 'deploy', 'deploy:cleanup'
after 'deploy:migrations', 'deploy:cleanup'

namespace :deploy do
  task :restart, :roles => :web do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :link_configs do
    run "cd #{release_path}; ln -s #{shared_path}/config/database.yml #{release_path}/config"
    run "cd #{release_path}; ln -s #{shared_path}/config/secret_key_base.key #{release_path}/config"
  end
end
