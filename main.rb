# encoding: UTF-8
require 'sinatra/base'

# require_relative './helper/auth'
require_relative './models/init' # gets Store
require_relative './db/config' # gets Database
# wann werden die Funktionen überall gebraucht? vllt doch register


class Main < Sinatra::Base
  VERSION = '0.1'

  $_db = Database.init 'development' # TODO make dynamic
  Store.init

  configure :development do
    disable :logging
  end

  get '/' do
    'Hallo ' + @id.to_s
  end

  # if Sinatra::Application.environment != 'test' # funktioniert nicht so gut. die tests sollten den auth header mitsenden, um auch authorisierung zu testen
  #   before do #auch mit negativem lookahead
  #     request.body.rewind
  #     @id = Auth.auth request.env['HTTP_AUTHORIZATION']
  #   end
  # end
end

require_relative './routes/user_layouts'
require_relative './routes/graphics'