require 'rake/testtask'
require_relative 'db/config'

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

namespace 'test' do
  desc "Run all tests"
  task(:all) do
    Dir['./tests/**/*_test.rb'].each { |file| load file }
  end
end

