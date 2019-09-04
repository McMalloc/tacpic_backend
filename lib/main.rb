# encoding: UTF-8
require 'sinatra/base'

# require_relative './helper/auth'
require_relative 'models/init' # gets Store
require_relative 'db/config' # gets Database
# wann werden die Funktionen überall gebraucht? vllt doch register


class Tacpic < Sinatra::Base
  VERSION = '0.1'

  puts ENV
  $_db = Database.init 'development' # TODO make dynamic
  Store.init

  configure do
    set :environemnt, :production
  end

  configure :development do
    enable :logging, :dump_errors, :raise_errors
  end

  configure :production do
    set :raise_errors, false #false will show nicer error page
    set :show_exceptions, false #true will ignore raise_errors and display backtrace in browser
  end

  get '/' do
    '<h1>Hallo</h1>'
  end

  # if Sinatra::Application.environment != 'test' # funktioniert nicht so gut. die tests sollten den auth header mitsenden, um auch authorisierung zu testen
  #   before do #auch mit negativem lookahead
  #     request.body.rewind
  #     @id = Auth.auth request.env['HTTP_AUTHORIZATION']
  #   end
  # end
end

require_relative 'routes/user_layouts'
require_relative 'routes/graphics'