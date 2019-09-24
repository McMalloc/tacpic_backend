ENV['RACK_ENV'] = 'test' # TODO still neccessary?
$LOAD_PATH.unshift File.expand_path("..", __dir__)

require "main"
require "env"
require "rack/test"
require "minitest/autorun"
require 'minitest/reporters'
require 'json'

include Rack::Test::Methods

def app
  Tacpic
end
#

$db =  Database.init ENV['TACPIC_DATABASE_URL']

MiniTest::Reporters.use! [MiniTest::Reporters::SpecReporter.new]