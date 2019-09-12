require 'rake/testtask'
require 'yard'
require_relative 'lib/db/config'
require_relative 'load_env'

ENV['SINATRA_ACTIVESUPPORT_WARNING'] = 'false'

config = parse_config

# currently, the user, url and database in general needs to be the same per machine/env
namespace 'db' do
  desc "Run database migrations"
  task :migrate, :mode do |t, args|
    url = Database.url(
        config['DB_USER'],
        config['DB_PASSWORD'],
        config['DB_NAME'],
        config['DB_URL'],
        args[:mode])
    sh "sequel -m lib/db/migrations #{url}"
  end

  desc 'Zap the database by running all the down migrations'
  task :zap, [:mode] do |t, args|
    url = Database.url(
        config['DB_USER'],
        config['DB_PASSWORD'],
        config['DB_NAME'],
        config['DB_URL'],
        args[:mode])
    sh "sequel -m lib/db/migrations -M 0 #{url}"
  end

  task :populate, [:mode] do |t, args|
    sh "ruby tests/populate_db.rb #{args[:mode]}"
  end

  desc 'Zaps the database then run the migrations'
  task :purge, [:mode] => [:zap, :migrate]

  desc 'Performs factory reset: Zap, migrate, repopulate'
  task :reset, [:mode] => [:zap, :migrate, :populate]
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