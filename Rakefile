require 'rake/testtask'
require_relative 'lib/db/config'

namespace 'db' do
  desc "Run database migrations where mode is: #{Database::DB_MODES.join(', ')}"
  task :migrate, :mode do |t, args|
    cmd = "sequel -m db/migrations #{Database.url(args[:mode])}"
    puts cmd
    puts `#{cmd}`
  end

  desc 'Zap the database by running all the down migrations'
  task :zap, [:mode] do |t, args|
    cmd = "sequel -m db/migrations -M 0 #{Database.url(args[:mode])}"
    puts cmd
    puts `#{cmd}`
  end

  desc 'Reset the database then run the migrations'
  task :reset, [:mode] => [:zap, :migrate]
end

Rake::TestTask.new do |t|
  # t.name = "all tests"
  # alternative call without rake:
  # ruby -I . -r ./tests/test_helper.rb ./tests/user_tests.rb
  t.libs << "."
  t.test_files = FileList['tests/*_tests.rb']
  t.verbose = true
end

