require_relative '../constants'
require_relative '../db/config'
require_relative '../models/init'
require_relative '../env.rb'
require_relative '../helper/functions'
require_relative '../services/commerce/commerce_data'

require 'logger'
require 'pry'
require 'base64'
require "rqrcode"
require 'csv'
require 'mail'
require 'rrtf'
require 'singleton'
require 'json'
require 'i18n'
require 'yaml'
require 'open3'


$_db = Database.init ENV['TACPIC_DATABASE_URL']
$_logger = Logger.new $stdout
Store.init

# mail = Mail.new do
#   from     'localhost'
#   to       'robert@tacpic.de'
#   subject  'Here is the image you wanted'
#   body     'testest'
# end
#
# puts mail.to_s
# mail.delivery_method :sendmail
# mail.deliver