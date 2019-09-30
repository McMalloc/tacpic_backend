# encoding: UTF-8
require 'roda'

# require_relative './helper/auth'
require_relative 'models/init' # gets Store
require_relative 'db/config' # gets Database
require_relative 'env' # gets Config
require_relative 'helper/functions'

class Tacpic < Roda
  VERSION = '0.1'

  $_db = Database.init ENV['TACPIC_DATABASE_URL']
  Store.init

  plugin :route_csrf, :csrf_failure=>:clear_session

  # handle json responses, serialize Sequel models
  plugin :json, classes: [Array, Hash, Sequel::Model]
  plugin :json_parser

  plugin :multi_route

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
        # backtrace: e.backtrace,
        message: e.message
    }
  end

  puts "loading routes"

  route(&:multi_route)

  # route do |r|
  #   r.on "a" do           # /a branch
  #
  #     r.on "b" do         # /a/b branch
  #
  #       r.is "c" do       # /a/b/c request
  #         r.get do
  #           "GET /a/b/c"
  #         end    # GET  /a/b/c request
  #         r.post do
  #           "POST /a/b/c"
  #         end   # POST /a/b/c request
  #       end
  #
  #       r.is "c", Integer do |id|       # /a/b/c request
  #         r.get do
  #           "GET /a/b/c/" + id.to_s
  #         end    # GET  /a/b/c request
  #         r.post do
  #           "POST /a/b/c" + id.to_s
  #         end   # POST /a/b/c request
  #       end
  #       r.get "d" do end  # GET  /a/b/d request
  #       r.post "e" do end # POST /a/b/e request
  #     end
  #   end
  # end
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
require_relative 'routes/versions'
# require_relative 'routes/variants'
# require_relative 'routes/user_layouts'
#