# encoding: UTF-8
require 'sinatra/base'

# require_relative './helper/auth'
require_relative '../models/init' # gets Store
require_relative '../db/config' # gets Database
# wann werden die Funktionen überall gebraucht? vllt doch register


$_db = Database.init 'development' # TODO make dynamic
Store.init

