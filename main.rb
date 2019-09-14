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

  route do |r|
    # GET / request
    r.root do
      "hello"
    end
  end
end

# require_relative 'routes/users'
# require_relative 'routes/user_layouts'
# require_relative 'routes/graphics'