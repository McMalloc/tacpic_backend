require 'roda'
require 'logger'
require 'csv'
require 'mail'
require 'rrtf'
require 'singleton'
require 'json'
require 'i18n'
require 'yaml'

# require_relative './helper/auth'
require_relative 'constants'
require_relative 'models/init' # gets Store
require_relative 'db/config' # gets Database
require_relative 'env' # gets Config
require_relative 'helper/functions'
require_relative 'helper/exceptions'

# business logic and rules
require_relative 'services/commerce/commerce_data'
require_relative 'services/haendlerbund/legal_api'
require_relative 'services/internetmarke/internetmarke'
require_relative 'services/mail/mail'
require_relative 'services/commerce/Quote'
require_relative 'services/commerce/PriceCalculator'
require_relative 'services/ocr/ocr'
require_relative 'services/job/job'
require_relative 'services/files/file'

require 'pry' if ENV['RACK_ENV'] != 'production'

class Tacpic < Roda
  $_db = Database.init ENV['TACPIC_DATABASE_URL']
  $_db.extension :pg_trgm # https://github.com/mitchellhenke/sequel-pg-trgm
  $_version = JSON.parse(File.read('public/BACKEND.json'))['tag']
  # $_db.extension :pg_array

  Store.init
  SMTP.init

  I18n.load_path << Dir[File.expand_path('i18n') + '/*.yml']
  I18n.default_locale = :de

  plugin :route_csrf
  # handle json responses, serialize Sequel models
  plugin :json, classes: [Array, Hash, Sequel::Model]
  plugin :json_parser
  plugin :request_headers
  plugin :hash_routes
  plugin :render
  plugin :public # , root: 'static'
  plugin :sinatra_helpers

  Dir.mkdir('logs') unless Dir.exist?('logs')
  $_logger = Logger.new('logs/log_' + Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')) # ISO 8601 time format
  plugin :common_logger, $_logger

  secret = SecureRandom.random_bytes(64)
  # read and instantly delete sensitive information from the ENV hash
  # secret = ENV.delete('TACPIC_SESSION_SECRET') || SecureRandom.random_bytes(64)
  plugin :sessions, secret: secret, key: 'rodauth.session'
  plugin :error_handler

  route do |r|
    r.rodauth
    r.public
    r.hash_routes
  end
end

at_exit do
  puts 'shutting down'
end

require_relative 'errors'
require_relative 'auth'

# routes
require_relative 'routes/graphics'
require_relative 'routes/variants'
require_relative 'routes/tags'
require_relative 'routes/users'
require_relative 'routes/orders'
require_relative 'routes/quotes'
require_relative 'routes/trace'
require_relative 'routes/legal'
require_relative 'routes/internal/index'
require_relative 'routes/internal/index'
