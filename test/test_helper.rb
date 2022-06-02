$LOAD_PATH.unshift File.expand_path('..', __dir__)

require 'main'
require 'constants'
require 'env'
require 'rack/test'
require 'minitest/autorun'
# require 'minitest/reporters'
require 'json'
require 'erb'
require 'faker'
require 'factory_bot'
require 'open3'

# include rack-specific test methods like post or get
include Rack::Test::Methods

include FactoryBot::Syntax::Methods
FactoryBot.find_definitions

$db = Database.init ENV['TACPIC_DATABASE_URL']

# shared methods
def app
  Tacpic
end

def get_body(response)
  JSON.parse(response.body)
end

def read_test_data(name, bindings = nil)
  if bindings.nil?
    File.read("./test/test_data/#{name}.json")
  else
    ERB.new(File.read("./test/test_data/#{name}.json.erb"))
       .result_with_hash(bindings)
  end
end

def count_files(relative_path)
  Dir[File.join(ENV['APPLICATION_BASE'], relative_path, '**', '*')].count { |file| File.file?(file) }
end

def present_in_pdf(path, text)
  Open3.capture3("pdfgrep #{text} #{path}")[2].success?
end

def replace_test_data(json, key, value)
  parsed = JSON.parse(json)
  parsed[key] = value
  parsed.to_json
end

def compare_images(image, ref, margin = 1, algorithm = 'ae')
  command =
    "compare -metric #{algorithm} #{ENV['APPLICATION_BASE']}/test/references/#{ref}.png -fuzz #{margin}% #{ENV['APPLICATION_BASE']}/files/#{image}.png #{ENV['APPLICATION_BASE']}/test/results/DIFF_#{image}.png"

  # ImageMagick writes the result to stderr if the output is another image whose data can optinally be captured in stdout
  stdout, stderr, status = Open3.capture3(command)
  stderr.to_i
end

# creating valid test user
def create_test_user(login, password)
  register_data = {
    'login': login,
    'login-confirm': login,
    'display_name': '',
    'password': password,
    'password-confirm': password
  }

  header 'Content-Type', 'application/json'
  post 'create-account', register_data.to_json, { 'content-type' => 'application/json' }

  data = {
    login: login,
    password: password
  }

  # get test user token
  header 'Content-Type', 'application/json'
  post 'login', data.to_json

  user = User.where(email: login).first

  Address.create(
    is_invoice_addr: false,
    street: 'Route',
    house_number: 32,
    company_name: 'Devon',
    first_name: 'Gary',
    last_name: 'Eich',
    city: 'Alabastia',
    zip: '34563',
    user_id: user.id
  )

  UserRights.create(
    user_id: user.id,
    can_order: true,
    can_hide_variants: true,
    can_view_admin: true,
    can_edit_admin: true
  )

  [last_response.original_headers['Authorization'], user]
end

$token, $test_user = create_test_user('test@tacpic.de', '12345678')

# creating fixtures
# require_relative 'populate_with_fixtures'
