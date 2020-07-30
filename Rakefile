require 'rake/testtask'
require 'yard'
require 'sequel'
require 'digest'
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
    # seed fix data
    sh "ruby db/seed.rb"
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

  # TODO deprecated, now part of app migrations
  # desc 'Setting up database tables for authentication provided by rodauth'
  # task :migrate_auth do |t, args|
  #   Sequel::Migrator.run(_db, './db/auth_migrations', table: 'schema_info_password')
  # end
  #
  # desc 'Zapping database tables for authentication provided by rodauth'
  # task :zap_auth do |t, args|
  #   Sequel::Migrator.run(_db, './db/auth_migrations', target: 0, table: 'schema_info_password')
  # end
  #
  # desc 'Reset authentication database'
  # task :reset_auth => [:zap_auth, :migrate_auth]

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
  task :purge_and_routes, [:mode] => ['db:purge', :routes]
  task :reset_and_routes, [:mode] => ['db:reset', :routes]
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

  desc 'Pulls new frontend and backend code, builds new react app (if neccessary), copies build and starts application, in background'
  task :force do

  end

  task :main do
    puts "▶ Are you sure?".magenta.bold + " (type yes to continue)".magenta
    answer = STDIN.gets.chomp
    unless answer == "yes"
      puts "Pff like OKAY, now exiting."
      exit
    end

    base = ENV['APPLICATION_BASE']
    puts "Staging backend:".black.bg_cyan
    Dir.chdir("#{base}") do
      puts "Compare backend masters"
      system "git remote update"
      rev_local = `git rev-parse master`
      rev_remote = `git rev-parse origin/master`
      if rev_local == rev_remote
        puts "No change, ".green.bold + "Skipping."
      else
        puts "Change in backend repository detected.".blue.bold
        digest_gemfile_old = Digest::SHA256.digest File.read 'Gemfile'
        digest_package_old = Digest::SHA256.digest File.read 'package.json'
        system "git pull"
        system "git describe --tags > public/BACKEND_VERSION.txt"
        digest_gemfile_new = Digest::SHA256.digest File.read 'Gemfile'
        if digest_gemfile_new != digest_gemfile_old
          puts "Gemfile " + digest_gemfile_new + " differs from " + digest_gemfile_old + ", reinstalling bundle."
          system "bundle install"
        end
        digest_package_new = Digest::SHA256.digest File.read 'package.json'
        if digest_package_new != digest_package_old
          puts "Package.json " + digest_package_new + " differs from " + digest_package_old + ", reinstalling package."
          system "npm install" # if package.json was modified
        end
      end
    end

    puts "Staging frontend:".black.bg_cyan
    Dir.chdir("#{base}/../tacpic") do
      puts "Compare frontend masters"
      system "git remote update"
      rev_local = `git rev-parse master`
      rev_remote = `git rev-parse origin/master`

      if rev_local == rev_remote
        puts "No change, ".green.bold + "Skipping."
      else
        puts "Change in frontend repository detected.".blue.bold
        digest_package_old = Digest::SHA256.digest File.read 'package.json'
        system "git pull"
        system "git describe --tags > public/FRONTEND_VERSION.txt"
        digest_package_new = Digest::SHA256.digest File.read 'package.json'
        if digest_package_new != digest_package_old
          puts "Package.json (frontend) " + digest_package_new.magenta + " differs from " + digest_package_old.magenta + ", reinstalling package."
          system "npm install" # if package.json was modified
        end
        system "npm run build"
      end
    end

    unless Dir.exists?("#{base}/public")
      system "mkdir #{base}/tacpic_backend/public"
    end

    puts "Copying #{base}/../tacpic/build/* to /var/www/frontend/"
    if system "cp -r #{base}/../tacpic/build/* /var/www/frontend/"
      puts "Success!".black.bg_green
    end
  end
end

namespace 'doc' do
  YARD::Rake::YardocTask.new do |t|
    t.name = 'all'
    t.files = %w(./**/*.rb ./tests/*.rb)
  end
end