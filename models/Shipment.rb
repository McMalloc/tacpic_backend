class Shipment < Sequel::Model
  one_to_one :address
  one_to_many :shipped_items
end
