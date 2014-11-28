require_relative 'init'

namespace :db do
  task :migrate do
    ActiveRecord::Migrator.migrations_paths = ['db/migrate']
    ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths, nil)
  end

  task :rollback do
    ActiveRecord::Migrator.migrations_paths = ['db/migrate']
    ActiveRecord::Migrator.rollback(ActiveRecord::Migrator.migrations_paths, 1)
  end
end
