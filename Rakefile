require 'rake/testtask'
require 'yard'
require 'sequel'
require_relative 'db/config'
require_relative 'env'
require_relative 'terminal_colors'

Sequel.extension :migration
# currently, the user, url and database in general needs to be the same per machine/env
namespace 'db' do
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
    system "rackup"
  end
  
  task :rerun do
    system 'rerun --background rackup'
  end
end

namespace 'stage' do
  task :main do
    if ENV['RACK_ENV'] == 'development'
      puts "\tℹ | Staging is not available on development environments.".blue.bold
      exit
    end

    puts "\t▶ | Are you sure?".magenta.bold + " (type yes to continue)".magenta
    answer = STDIN.gets.chomp
    unless answer == "yes"
      puts "Pff like OKAY, now exiting."
      exit
    end

    base = ENV['APPLICATION_BASE']
    puts "Staging backend:".black.bg_cyan
    Dir.chdir("#{base}/tacpic") do
      system "git pull"
      system "bundle install" # if package.json was modified
    end

    puts "Staging frontend:".black.bg_cyan
    Dir.chdir("#{base}/tacpic_backend") do
      puts "Checking if pull and rebuild is neccessary ..."
      system "git remote update"
      rev_local = system "git rev-parse master"
      rev_remote = system "git rev-parse origin/master"
      if rev_local == rev_remote
        puts "Nope! ".green.bold + "Skipping."
      else
        puts "Yes! ".blue.bold + "P."
        system "git pull"
        system "npm install" # if Gemfile was specified
        system "npm run build" # if Gemfile was specified
      end
    end

    unless Dir.exists?("#{base}/tacpic_backend/public")
      system "mkdir #{base}/tacpic_backend/public"
    end

    puts "Copying #{base}/tacpic/build/* to #{base}/tacpic_backend/public ... "
    if system "cp -r #{base}/tacpic/build/* #{base}/tacpic_backend/public"
      print "Success!".black.green_bg
    end

    puts "Starting application server".black.green_bg
    Dir.chdir("#{base}/tacpic_backend") do
      system "rake run:main RACK_ENV=production"
    end
  end
end

namespace 'doc' do
  YARD::Rake::YardocTask.new do |t|
    t.name = 'all'
    t.files = %w(./**/*.rb ./tests/*.rb)
  end
end