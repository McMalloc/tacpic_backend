require_relative '../db/config'
require_relative '../models/init'
require_relative '../env.rb'
require_relative '../helper/functions'
require_relative '../services/commerce/commerce_data'

# require 'mail'

$_db = Database.init ENV['TACPIC_DATABASE_URL']
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