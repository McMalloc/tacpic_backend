# encoding: UTF-8
require 'sinatra/base'
require 'sequel'
require 'mysql2'
require 'dotenv'
require_relative './helper/auth'
# require 'json'

module Tacpic
  class App < Sinatra::Base
    configure do
      Dotenv.load 'dev.env'
      $_db = Sequel.connect(
          adapter: 'mysql2',
          user: 'tacpic',
          host: 'localhost',
          database: 'tacpic',
          password: ENV['DB_PASSWORD']
      )
    end

    get '/' do
      'Hallo ' + @id.to_s
    end

    post '/user/layout' do
      $_db[:user_layouts].insert(
                             user_id: @id,
                             name: 'Layout',
                             created_at: Date.today,
                             layout: request.body.read
      )
      status 202
    end

    before do #auch mit negativem lookahead
      request.body.rewind
      @id = Auth.auth request.env['HTTP_AUTHORIZATION']
    end
  end
end
