# encoding: UTF-8
require 'roda'

# require_relative './helper/auth'
require_relative 'models/init' # gets Store
require_relative 'db/config' # gets Database
require_relative 'env' # gets Config

class Tacpic < Roda
  VERSION = '0.1'

  $_db = Database.init ENV['TACPIC_DATABASE_URL']
  Store.init

  plugin :route_csrf, :csrf_failure=>:clear_session

  # handle json responses, serialize Sequel models
  plugin :json, classes: [Array, Hash, Sequel::Model]
  plugin :json_parser

  plugin :rodauth, json: :only, csrf: :route_csrf do
    enable :login, :logout, :jwt
    after_login do
      LOGGER.info "#{account[:email]} logged in!"
    end
  end

  # enable :logging
  # file = File.new("#{File.expand_path File.dirname(__FILE__)}/logs/#{ENV['RACK_ENV']}.log", 'a+')
  # file.sync = true
  # use Rack::CommonLogger, file

  plugin :error_handler do |e|
    {
        type: e.class.name,
        backtrace: e.backtrace,
        message: e.message
    }
  end

  puts "loading routes"
  route do |r|
    # GET / request
    r.root do
      @graphics = Graphic.all
      @graphics.map(&:values)
    end
  end
end

# thrown when requesting parameters compromise the sanity of the response
class DataError < StandardError
  attr_reader :parameter
  def initialize(msg="The request cannot reasonably be processed.", parameter)
    @parameter = parameter
    super
  end
end

require_relative 'routes/graphics'
# require_relative 'routes/variants'
# require_relative 'routes/user_layouts'
#