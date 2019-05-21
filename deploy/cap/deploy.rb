# config valid only for current version of Capistrano
lock '3.11.0'

set :application, 'sparkle'
set :repo_url, 'git@github.com:mackuba/sparkler.git'
set :bundle_jobs, 2
set :rails_env, 'production'

# this is the path of the directory where the app will be deployed on your server (default = /var/www/app_name)
set :deploy_to, '/var/www/sparkle'

set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secret_key_base.key')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'public/assets', 'public/system')
set :optional_symlinks, ['config/reload_key.key']

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

after "deploy:symlink:linked_dirs", :optional_symlinks do
  on release_roles :all do |host|
    fetch(:optional_symlinks, []).each do |file|
      target = release_path.join(file)
      source = shared_path.join(file)

      if test("[ -f #{source} ]")
        next if test "[ -L #{target} ]"
        execute :rm, target if test "[ -f #{target} ]"
        execute :ln, "-s", source, target
      else
        info "Skipping optional symlink #{file}"
      end
    end
  end
end
