# encoding: UTF-8
require 'roda'
require 'logger'
require 'csv'

# require_relative './helper/auth'
require_relative 'models/init' # gets Store
require_relative 'db/config' # gets Database
require_relative 'env' # gets Config
require_relative 'helper/functions'

class Tacpic < Roda
  $_backend_version = File.read "public/BACKEND_VERSION.txt"

  $_db = Database.init ENV['TACPIC_DATABASE_URL']
  $_db.extension :pg_trgm #https://github.com/mitchellhenke/sequel-pg-trgm
  # $_db.extension :pg_array
  Store.init

  plugin :route_csrf
  # handle json responses, serialize Sequel models
  plugin :json, classes: [Array, Hash, Sequel::Model]
  plugin :json_parser
  plugin :request_headers
  plugin :hash_routes
  plugin :public #, root: 'static'
  plugin :sinatra_helpers

  unless Dir.exists?("logs")
    Dir.mkdir("logs")
  end

  plugin :common_logger, Logger.new('logs/log_' + Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')) # ISO 8601 time format
  plugin :common_logger, $stdout

  secret = SecureRandom.random_bytes(64)
  # read and instantly delete sensitive information from the ENV hash
  # secret = ENV.delete('RODAUTH_SESSION_SECRET') || SecureRandom.random_bytes(64)
  plugin :sessions, :secret => secret, :key => 'rodauth.session'
  plugin :rodauth, json: :only, csrf: :route_csrf do

    login_required_error_status 401
    enable :login, :logout, :jwt, :create_account#, :jwt_cors#, :session_expiration
    # :verify_account # requires an SMTP server on port 25 by default
    # jwt_cors_allow_origin 'http://localhost:3000'
    accounts_table :users
    # jwt_cors_allow_methods 'GET', 'POST'

    jwt_secret ENV.delete('TACPIC_SESSION_SECRET')
    # max_session_lifetime 86400

    # after_login do
    #   response.write @account.to_json
    # end

    before_create_account do
      # @account[:display_name] = request.params['display_name']
      @account[:created_at] = Time.now.to_s
    end

    # after_create_account do
    #   response.write(@account.to_json)
    # end
  end

  plugin :error_handler do |e|
    {
        type: e.class.name,
        backtrace: e.backtrace,
        message: e.message
    }
  end

  route do |r|

    r.rodauth

    r.root do
      send_file "public/index.html"
    end

    r.public
    r.hash_routes

    # if no api or root call, send the react app to handle the url
    r.is /.+/ do
      send_file "public/index.html"
    end
  end
end

# thrown when requesting parameters compromise the sanity of the response
class DataError < StandardError
  attr_reader :parameter

  def initialize(msg = "The request cannot reasonably be processed.", parameter)
    @parameter = parameter
    super
  end
end

# business logic and rules
require_relative 'services/internetmarke/internetmarke'
require_relative 'services/commerce/Quote'
require_relative 'services/commerce/GraphicPriceCalculator'

# routes
require_relative 'routes/graphics'
require_relative 'routes/variants'
require_relative 'routes/tags'
require_relative 'routes/users'
require_relative 'routes/orders'
require_relative 'routes/braille'
#
# require_relative 'routes/backend/users'