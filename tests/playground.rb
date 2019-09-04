# encoding: UTF-8
require 'sinatra/base'

# require_relative './helper/auth'
require_relative '../lib/models/init' # gets Store
require_relative '../lib/db/config' # gets Database
# wann werden die Funktionen überall gebraucht? vllt doch register


$_db = Database.init 'development' # TODO make dynamic
Store.init

