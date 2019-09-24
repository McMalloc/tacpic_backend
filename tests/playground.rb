require_relative '../db/config'
require_relative '../models/init'
require_relative '../env.rb'

$_db = Database.init ENV['TACPIC_DATABASE_URL']
Store.init

