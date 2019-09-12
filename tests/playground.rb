# encoding: UTF-8
require 'sinatra/base'

# require_relative './helper/auth'
require_relative '../lib/models/init' # gets Store
require_relative '../lib/db/config' # gets Database
require_relative '../load_env' # gets Config
config = parse_config
$_db = Database.init config['DB_USER'],
                     config['DB_PASSWORD'],
                     config['DB_NAME'],
                     config['DB_URL'],
                     'development'
Store.init

