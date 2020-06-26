$LOAD_PATH.unshift File.expand_path("..", __dir__)

require "main"
require "env"
require "rack/test"
require "minitest/autorun"
require 'minitest/reporters'
require 'json'
require "faker"

include Rack::Test::Methods

# shared methods
def app
  Tacpic
end

def get_body(response)
  JSON.parse(response.body)
end

# creating valid test user
register_data = {
    'login': 'test@test.de',
    'login-confirm': 'test@test.de',
    'password': 'testtest',
    'password-confirm': 'testtest',
}
header 'Content-Type', 'application/json'
post 'create-account', register_data.to_json, { 'content-type' => 'application/json' }

data = {
    login: 'test@test.de',
    password: 'testtest',
}

# get test user token
header 'Content-Type', 'application/json'
post 'login', data.to_json

$token = last_response.original_headers['Authorization']
$db = Database.init ENV['TACPIC_DATABASE_URL']
$test_user_id = User.where(email: 'test@test.de').first.id

# creating fixtures
require_relative 'populate_with_fixtures'

MiniTest::Reporters.use! [MiniTest::Reporters::SpecReporter.new]