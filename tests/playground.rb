require_relative '../db/config'
require_relative '../models/init'
require_relative '../env.rb'
require_relative '../helper/functions'

$_db = Database.init ENV['TACPIC_DATABASE_URL']
Store.init