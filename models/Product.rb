class Product < Sequel::Model
  many_to_many :order_items
  one_to_one :base_prices
end
