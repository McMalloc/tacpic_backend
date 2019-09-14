require 'rake/testtask'
require 'yard'
require 'sequel'
require_relative 'db/config'
require_relative 'env'

Sequel.extension :migration
# currently, the user, url and database in general needs to be the same per machine/env
namespace 'db' do
  _db = Database.init ENV['TACPIC_DATABASE_URL']

  desc "Run database migrations"
  task :migrate do |t, args|
    Sequel::Migrator.run(_db, './db/migrations')
  end

  desc 'Zap the database by running all the down migrations'
  task :zap do |t, args|
    Sequel::Migrator.run(_db, './db/migrations', target: 0)
  end

  desc 'Populate database with test data'
  task :populate, [:mode] do |t, args|
    sh "ruby tests/populate_db.rb #{ENV['RACK_ENV']}"
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

  desc 'Zaps the database then run the migrations'
  task :purge => [:zap, :migrate]

  desc 'Performs factory reset: Zap, migrate, repopulate'
  task :reset => [:zap, :migrate, :populate]
end

namespace 'test' do
  Rake::TestTask.new do |t|
    t.name = 'all'
    t.libs << "."
    t.test_files = FileList['tests/*_tests.rb']
    t.verbose = true
    t.warning = false

    # gets called everytime?
    # at_exit { Rake::Task['db:purge'].invoke("test") }
  end

  Rake::TestTask.new do |t|
    t.name = 'models'
    # t.libs << "."
    t.test_files = FileList['tests/model_tests.rb']
    t.verbose = true
    t.warning = false
  end

  desc 'Purges test db and runs model tests'
  task :purge_and_models, [:mode] => ['db:purge', :models]
end

namespace 'run' do
  task :main do
    sh "rackup"
  end
end

namespace 'doc' do
  YARD::Rake::YardocTask.new do |t|
    t.name = 'all'
    t.files = %w(./lib/**/*.rb ./tests/*.rb)
  end
  # task :main do
  #   sh "yard "
  # end
end