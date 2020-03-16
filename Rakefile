require 'rake/testtask'
require 'yard'
require 'sequel'
require_relative 'db/config'
require_relative 'env'

Sequel.extension :migration
# currently, the user, url and database in general needs to be the same per machine/env
namespace 'db' do
  puts ENV['TACPIC_DATABASE_URL']
  _db = Database.init ENV['TACPIC_DATABASE_URL']

  desc "Run database app_migrations"
  task :migrate do |t, args|
    Sequel::Migrator.run(_db, './db/app_migrations')
  end

  desc 'Zap the database by running all the down app_migrations'
  task :zap do |t, args|
    Sequel::Migrator.run(_db, './db/app_migrations', target: 0)
  end

  desc 'Populate database with test data'
  task :populate, [:mode] do |t, args|
    sh "ruby tests/populate_db.rb"
  end

  desc 'Copy contents of the example database (tacpic-template) to the test database'
  task :mirror do
    sh "sequel -C postgres://tacpic-dev:tacpic@localhost/tacpic-template postgres://tacpic-dev:tacpic@localhost/tacpic-test"
  end

  desc 'Setting up database tables for authentication provided by rodauth'
  task :migrate_auth do |t, args|
    Sequel::Migrator.run(_db, './db/auth_migrations', table: 'schema_info_password')
  end

  desc 'Zapping database tables for authentication provided by rodauth'
  task :zap_auth do |t, args|
    Sequel::Migrator.run(_db, './db/auth_migrations', target: 0, table: 'schema_info_password')
  end

  desc 'Reset authentication database'
  task :reset_auth => [:zap_auth, :migrate_auth]

  desc 'Zaps the database then run the app_migrations'
  task :purge => [:zap, :migrate]

  desc 'Performs factory reset: Zap, migrate, repopulate'
  task :reset => [:zap, :migrate, :populate]

  desc 'zaps the database and copys example data'
  task :reset_and_mirror => [:zap, :mirror]
end

namespace 'test' do
  Rake::TestTask.new do |t|
    t.name = 'routes'
    t.libs << "."
    t.test_files = FileList['tests/*_tests.rb']
    t.verbose = true
    t.warning = false
  end

  Rake::TestTask.new do |t|
    t.name = 'models'
    # t.libs << "."
    t.test_files = FileList['tests/model_tests.rb']
    t.verbose = true
    t.warning = false
  end

  desc 'Purges test db and runs model tests'
  # task :purge_and_models, [:mode] => ['db:purge', :models]
  task :purge_and_routes, [:mode] => ['db:reset', :routes]
  # task :all_routes, [:mode] => [:routes]
end

namespace 'run' do
  task :main do
    sh "rackup"
  end
  task :rerun do
    sh 'rerun --background rackup'
  end
end

namespace 'doc' do
  YARD::Rake::YardocTask.new do |t|
    t.name = 'all'
    t.files = %w(./**/*.rb ./tests/*.rb)
  end
end