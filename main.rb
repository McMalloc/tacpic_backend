# encoding: UTF-8
require 'roda'
require 'logger'
require 'csv'
require 'mail'
require 'singleton'
require 'json'

# require_relative './helper/auth'
require_relative 'models/init' # gets Store
require_relative 'db/config' # gets Database
require_relative 'env' # gets Config
require_relative 'helper/functions'
require_relative 'helper/exceptions'

require_relative 'services/haendlerbund/legal_api'

require 'pry' if ENV["RACK_ENV"] == "development"

class Tacpic < Roda
  $_db = Database.init ENV['TACPIC_DATABASE_URL']
  $_db.extension :pg_trgm #https://github.com/mitchellhenke/sequel-pg-trgm
  $_version = JSON.parse(File.read 'public/BACKEND.json')['tag']
  # $_db.extension :pg_array
  Store.init
  LegalAPI.instance.init



  Mail.defaults do
    delivery_method :smtp, {address: ENV['SMTP_SERVER'],
                            port: ENV['SMTP_PORT'],
                            domain: ENV['SMTP_HELOHOST'],
                            user_name: ENV['SMTP_USER'],
                            password: ENV.delete('SMTP_PASSWORD'),
                            authentication: 'login',
                            enable_starttls_auto: true}
  end

  plugin :route_csrf
  # handle json responses, serialize Sequel models
  plugin :json, classes: [Array, Hash, Sequel::Model]
  plugin :json_parser
  plugin :request_headers
  plugin :hash_routes
  plugin :render
  plugin :public #, root: 'static'
  plugin :sinatra_helpers
  # plugin :all_verbs

  unless Dir.exists?("logs")
    Dir.mkdir("logs")
  end

  plugin :common_logger, Logger.new('logs/log_' + Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')) # ISO 8601 time format

  secret = SecureRandom.random_bytes(64)
  # read and instantly delete sensitive information from the ENV hash
  # secret = ENV.delete('TACPIC_SESSION_SECRET') || SecureRandom.random_bytes(64)
  plugin :sessions, :secret => secret, :key => 'rodauth.session'
  plugin :rodauth, json: :only, csrf: :route_csrf do

    login_required_error_status 401
    enable :login, :logout, :jwt, :create_account, :reset_password #, :jwt_cors#, :session_expiration

    # EMAIL CONFIG
    unless ENV['RACK_ENV'] == 'test'
      enable :verify_account

      verify_account_email_subject 'tacpic: Bestätigung Ihrer E-Mail-Adresse'
      # verify_account_email_body "#{verify_account_email_link}"
      email_from 'kontoverwaltung@tacpic.de'
      after_verify_account do
        response.write @account.to_json
      end

      verify_account_email_body do
        SMTP::render(:verify_account, {url: verify_account_email_link})
      end
    end

    reset_password_email_subject 'tacpic: Zurücksetzen Ihres Passworts'
    reset_password_email_body do
      SMTP::render(:reset_password, {url: reset_password_email_link})
    end

    send_email do |email|
      email.content_type 'text/html; charset=UTF-8'
      super email
    end
    email_from 'kontoverwaltung@tacpic.de'

    accounts_table :users
    jwt_secret ENV.delete('TACPIC_SESSION_SECRET')
    # max_session_lifetime 86400
    after_login do
      response.write @account.to_json
    end

    before_create_account do
      unless request.params['display_name'].empty?
        @account[:display_name] = request.params['display_name']
      end
      @account[:newsletter_active] = request.params['newsletter_active']

      raise AccountError.new "not whitelisted" unless
          File.open(File.join(ENV['APPLICATION_BASE'], "config/whitelist.txt"))
              .read.split("\n").include? @account[:email]

      raise AccountError.new "display name already in use" unless
          User.find(display_name: request[:display_name]).nil?

      @account[:created_at] = Time.now.to_s
    end
  end

  plugin :error_handler do |e|
    logs = $_db[:backend_errors]
    request.body.rewind

    logs.insert(
      method: request.request_method,
      path: request.path,
      params: request.request_method == 'GET' ? request.query_string : request.body.read,
      frontend_version: request.headers['TACPIC_VERSION'],
      backend_version: $_version,
      type: e.class.name,
      backtrace: e.backtrace,
      message: e.message,
      created_at: Time.now
    )

    response.status = 500
    {
        type: e.class.name,
        message: e.message,
        backtrace: e.backtrace
    }
  end

  route do |r|
    r.rodauth
    r.public
    r.hash_routes
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
require_relative 'services/mail/mail'
require_relative 'services/commerce/Quote'
require_relative 'services/commerce/GraphicPriceCalculator'
require_relative 'services/ocr/ocr'
require_relative 'services/job/job'

# routes
require_relative 'routes/graphics'
require_relative 'routes/variants'
require_relative 'routes/tags'
require_relative 'routes/users'
require_relative 'routes/orders'
require_relative 'routes/quotes'
require_relative 'routes/braille'
require_relative 'routes/trace'
require_relative 'routes/legal'
require_relative 'routes/internal/index'
#
# require_relative 'routes/backend/users'