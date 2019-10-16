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
  Store.init

  plugin :route_csrf
  # handle json responses, serialize Sequel models
  plugin :json, classes: [Array, Hash, Sequel::Model]
  plugin :json_parser
  plugin :request_headers
  plugin :render, :escape => true
  plugin :multi_route
  plugin :common_logger, Logger.new('logs/log_' + Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')) # ISO 8601 time format

  secret = SecureRandom.random_bytes(64)
  # read and instantly delete sensitive information from the ENV hash
  # secret = ENV.delete('RODAUTH_SESSION_SECRET') || SecureRandom.random_bytes(64)
  plugin :sessions, :secret => secret, :key => 'rodauth-demo.session'
  plugin :rodauth, json: :only, csrf: :route_csrf do
    # plugin :rodauth, json: :only, csrf: :route_csrf do
    enable :login, :logout, :jwt, :create_account, :jwt_cors
    # , :verify_account # requires an SMTP server on port 25 by default
    create_account_route :users # was create-account
    jwt_cors_allow_origin 'http://localhost:3000'
    jwt_secret 'TEST_wRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'
    accounts_table :users
    after_login do
      ###
    end

    before_create_account do
      @account[:display_name] = request.params['display_name']
      puts "before create"
    end
  end

  plugin :error_handler do |e|
    {
        type: e.class.name,
        message: e.message
    }
  end

  route do |r|
    # csrf_token(path=nil, method='POST')
    # Handling of CORS preflight. All requests from the web app will be allowed.
    # TODO options request, aber falscher origin
    if request.request_method == 'OPTIONS' && request.env['HTTP_ORIGIN'] == 'http://localhost:3000'
      response['Access-Control-Allow-Origin'] = request.env['HTTP_ORIGIN']
      response['Access-Control-Allow-Methods'] = 'POST'
      response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, Accept'
      response['Access-Control-Max-Age'] = '86400'
      response.status = 204
      request.halt
    else
      r.rodauth
      r.multi_route
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

require_relative 'routes/graphics'
require_relative 'routes/versions'
require_relative 'routes/tags'
# require_relative 'routes/variants'
# require_relative 'routes/user_layouts'
#