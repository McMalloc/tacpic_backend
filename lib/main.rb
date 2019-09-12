# encoding: UTF-8
require 'sinatra/base'
require 'sinatra/namespace'

# require_relative './helper/auth'
require_relative 'models/init' # gets Store
require_relative 'db/config' # gets Database
require_relative '../load_env' # gets Config

class Tacpic < Sinatra::Base
  register Sinatra::Namespace
  VERSION = '0.1'

  configure do
    config = parse_config
    if settings.environment != :test then set :environment, config['ENV'] end
    set :server, :puma
    set :port, config['PORT']
    set :hmac, config['hmac']
    $_db = Database.init config['DB_USER'],
                         config['DB_PASSWORD'],
                         config['DB_NAME'],
                         config['DB_URL'],
                         settings.environment
    Store.init

    # configure differently for environments
    enable :logging
    file = File.new("#{File.expand_path File.dirname(__FILE__)}/logs/#{settings.environment}.log", 'a+')
    file.sync = true
    use Rack::CommonLogger, file
  end

  # configure :development do
  #   enable :logging, :dump_errors, :raise_errors
  # end
  #
  # configure :production do
  #   set :raise_errors, false #false will show nicer error page
  #   set :show_exceptions, false #true will ignore raise_errors and display backtrace in browser
  # end

  # main route
  #
  # @return [Array] a list of all valid routes
  get '/' do
    '<h1>Tacpic</h1><p>main route</p>'
  end
end

require_relative 'routes/users'
require_relative 'routes/user_layouts'
require_relative 'routes/graphics'