ENV['RACK_ENV'] = 'test' # TODO still neccessary?
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "main"
require "rack/test"
require "minitest/autorun"
require 'minitest/reporters'
require 'json'

require_relative '../lib/db/config' # gets Database
require_relative '../load_env' # gets Config

include Rack::Test::Methods

def app
  Tacpic.set :environment, :test
end

config = parse_config
$test_db =  Database.init config['DB_USER'],
                config['DB_PASSWORD'],
                config['DB_NAME'],
                config['DB_URL'],
                :test

# now in Rakefile
# MiniTest::after_run { sh 'rake db:reset[test]' }

MiniTest::Reporters.use! [MiniTest::Reporters::SpecReporter.new]