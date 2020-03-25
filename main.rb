# encoding: UTF-8
require 'roda'
require 'logger'

# require_relative './helper/auth'
require_relative 'models/init' # gets Store
require_relative 'db/config' # gets Database
require_relative 'env' # gets Config
require_relative 'helper/functions'

class Tacpic < Roda
  VERSION = '0.1'

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

  # TODO logs Ordner anlegen, sonst startet der Server beim ersten Mal nicht
  plugin :common_logger, Logger.new('logs/log_' + Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')) # ISO 8601 time format
  # plugin :common_logger, $stdout

  secret = SecureRandom.random_bytes(64)
  # read and instantly delete sensitive information from the ENV hash
  # secret = ENV.delete('RODAUTH_SESSION_SECRET') || SecureRandom.random_bytes(64)
  plugin :sessions, :secret => secret, :key => 'rodauth-demo.session'
  plugin :rodauth, json: :only, csrf: :route_csrf do

    enable :login, :logout, :jwt, :create_account#, :jwt_cors#, :session_expiration
    # :verify_account # requires an SMTP server on port 25 by default

    # jwt_cors_allow_origin 'http://localhost:3000'
    accounts_table :users
    # jwt_cors_allow_methods 'GET', 'POST'

    jwt_secret 'TEST_wRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'
    # max_session_lifetime 86400

    after_login do
      response.write(@account.to_json)
    end

    before_create_account do
      @account[:display_name] = request.params['display_name']
      @account[:created_at] = Time.now.to_s
    end

    after_create_account do
      response.write(@account.to_json)
    end
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
  end

  # route do |r|
  #   # rodauth.check_session_expiration
  #   #
  #   if r.env['REQUEST_METHOD'] == 'OPTIONS' && request.env['HTTP_ORIGIN'] == 'http://localhost:3000'
  #     response['Access-Control-Allow-Origin'] = request.env['HTTP_ORIGIN']
  #     response['Access-Control-Allow-Methods'] = 'POST'
  #     response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, Accept'
  #     response['Access-Control-Max-Age'] = '86400'
  #     response.status = 204
  #     request.halt
  #   end
  #
  #   r.rodauth
  #
  #   r.hash_routes
  #
  #   # r.on '/' do
  #   #   r.get do
  #   #     r.public
  #   #   end
  #   # end
  #
  #   # r.on :static do
  #   #   r.public
  #   # end
  # end

end

# thrown when requesting parameters compromise the sanity of the response
class DataError < StandardError
  attr_reader :parameter

  def initialize(msg = "The request cannot reasonably be processed.", parameter)
    @parameter = parameter
    super
  end
end

require_relative 'routes/graphics'
require_relative 'routes/versions'
require_relative 'routes/variants'
require_relative 'routes/tags'
require_relative 'routes/users'
require_relative 'routes/braille'
#
# require_relative 'routes/backend/users'