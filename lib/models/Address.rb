class Address < Sequel::Model
  many_to_one :user
  one_to_one :invoice
  one_to_one :shipment
end
