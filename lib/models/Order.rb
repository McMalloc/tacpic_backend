class Order < Sequel::Model
  many_to_one :user
  # one_to_many :order_items
  many_to_many :products, join_table: :ordered_items
  one_to_many :shipped_items
  one_to_one :invoice
end
