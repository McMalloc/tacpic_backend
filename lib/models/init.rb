require 'sequel'

module Store
  def self.init
    require_relative './User.rb'
    require_relative './Product.rb'
    require_relative './Graphic.rb'
    require_relative './Variant.rb'
    require_relative './Version.rb'
    require_relative './Tag.rb'
    require_relative './List.rb'
    require_relative './Fav.rb'
    require_relative './Download.rb'
    require_relative './Address.rb'
    require_relative './Order.rb'
    require_relative './OrderItem.rb'
    require_relative './Shipment.rb'
    require_relative './ShippedItem.rb'
    require_relative './Invoice.rb'
    require_relative './InvoiceItem.rb'
    require_relative './Payment.rb'
    require_relative './Tagging.rb'
    require_relative './UserLayout.rb'
    require_relative './Annotation.rb'
    require_relative './Comment.rb'
    # Dir.glob('./models/*.rb').each { |file| require file }
  end
end


