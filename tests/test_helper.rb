$LOAD_PATH.unshift File.expand_path("..", __dir__)

require "main"
require "env"
require "rack/test"
require "minitest/autorun"
# require 'minitest/reporters'
require 'json'
require "faker"

include Rack::Test::Methods
$db = Database.init ENV['TACPIC_DATABASE_URL']
# shared methods
def app
  Tacpic
end

def get_body(response)
  JSON.parse(response.body)
end

def read_test_data(name)
  File.open("./tests/test_data/" + name + ".json").read
end

def compare_images(image, ref, margin = 1, algorithm = 'ae')
  `compare 
    -metric #{algorithm} 
    #{ENV['APPLICATION_BASE']}/tests/references/#{ref}.png 
    -fuzz #{margin}% 
    #{ENV['APPLICATION_BASE']}/tests/results/#{image}.png 
    #{ENV['APPLICATION_BASE']}/tests/results/DIFF_#{image}.png`
end

# creating valid test user
def create_test_user(login, password)
  register_data = {
      'login': login,
      'login-confirm': login,
      'display_name': '',
      'password': password,
      'password-confirm': password,
  }

  header 'Content-Type', 'application/json'
  post 'create-account', register_data.to_json, { 'content-type' => 'application/json' }

  data = {
      login: login,
      password: password,
  }

# get test user token
  header 'Content-Type', 'application/json'
  post 'login', data.to_json

  {
      id: User.where(email: login).first.id,
      token: last_response.original_headers['Authorization']
  }
end

$token = create_test_user('test@test.de', '12345678')[:token]


# creating fixtures
# require_relative 'populate_with_fixtures'
# MiniTest::Reporters.use! [MiniTest::Reporters::SpecReporter.new]