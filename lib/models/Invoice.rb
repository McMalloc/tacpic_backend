class Invoice < Sequel::Model
  one_to_one :address
  many_to_many :order_items, join_table: :invoice_items
  one_to_many :payments
end
