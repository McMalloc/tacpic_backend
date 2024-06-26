require 'roda'
require 'logger'
require 'csv'
require 'mail'
require 'rrtf'
require 'singleton'
require 'json'
require 'i18n'
require 'yaml'
require 'open3'
require 'rufus-scheduler'

# require_relative './helper/auth'
require_relative 'constants'
require_relative 'models/init' # gets Store
require_relative 'db/config' # gets Database
require_relative 'env' # gets Config
require_relative 'helper/functions'
require_relative 'helper/exceptions'
require_relative 'terminal_colors'
require_relative 'logging'

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
  init_logging

  unless RUBY_VERSION === '2.7.0'
    $_logger.error "[ENV] The current ruby version is #{RUBY_VERSION}, but 2.7.0 is required. Exiting."
    exit!
  end

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

  %w[logs
     public/thumbnails
     files/invoices
     files/shipment_receipts
     files/temp
     files/vouchers
     files/jobs].each { |dir| Dir.mkdir(dir) unless Dir.exist?(dir) }

  secret = SecureRandom.random_bytes(64)
  # read and instantly delete sensitive information from the ENV hash
  # secret = ENV.delete('TACPIC_SESSION_SECRET') || SecureRandom.random_bytes(64)
  plugin :sessions, secret: secret, key: 'rodauth.session'
  plugin :error_handler

  $_logger.info 'Started app in env ' + ENV['RACK_ENV']

  route do |r|
    r.rodauth
    r.public
    r.hash_routes
  end

  s = Rufus::Scheduler.new
  s.cron '0 0 1 * *' do # 1st of month
    last_transaction = InternetmarkeTransaction.last
    SMTP::SendMail.instance.send_info(
      'Kontostand der Portokasse',
      "Stand mit Transaktions-ID #{last_transaction.id}: #{Helper.format_currency(last_transaction.balance)}",
      last_transaction.create_report,
      ENV['ACCOUNTING_ADDRESS']
    )
  end

  SMTP::SendMail.instance.send_info('Backend hochgefahren', 'Logfile siehe Anhang') if ENV['RACK_ENV'] == 'production'
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
require_relative 'routes/invoices'
require_relative 'routes/quotes'
require_relative 'routes/trace'
require_relative 'routes/legal'
require_relative 'routes/test' unless ENV['RACK_ENV'] == 'production'
require_relative 'routes/internal/index'
