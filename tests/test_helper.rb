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

register_data = {
    login: 'test@test.de',
    'login-confirm': 'test@test.de',
    password: 'testtest',
    'password-confirm': 'testtest',
}
header 'Content-Type', 'application/json'
post 'users', register_data.to_json, { 'content-type' => 'application/json' }

data = {
    login: 'test@test.de',
    password: 'testtest',
}

header 'Content-Type', 'application/json'
post 'login', data.to_json

$token = last_response.original_headers['Authorization']

def setup
  puts "Setup!"
end

$db = Database.init ENV['TACPIC_DATABASE_URL']

MiniTest::Reporters.use! [MiniTest::Reporters::SpecReporter.new]