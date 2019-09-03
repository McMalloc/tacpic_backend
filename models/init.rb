require 'sequel'

module Store
  def self.init
    require './models/User.rb'
    require './models/Product.rb'
    require './models/Graphic.rb'
    require './models/Variant.rb'
    require './models/Version.rb'
    require './models/Tag.rb'
    require './models/List.rb'
    require './models/Fav.rb'
    require './models/Download.rb'
    require './models/Address.rb'
    require './models/Order.rb'
    require './models/OrderItem.rb'
    require './models/Shipment.rb'
    require './models/ShippedItem.rb'
    require './models/Invoice.rb'
    require './models/InvoiceItem.rb'
    require './models/Payment.rb'
    require './models/Tagging.rb'
    require './models/UserLayout.rb'
    require './models/Annotation.rb'
    require './models/Comment.rb'
    # Dir.glob('./models/*.rb').each { |file| require file }
  end
end


