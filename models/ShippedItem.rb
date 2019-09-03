class ShippedItem < Sequel::Model
  many_to_one :shipment
end
