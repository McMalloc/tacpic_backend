class OrderItem < Sequel::Model
  many_to_many :invoice, join_table: :invoice_item
  many_to_one :order
  one_to_many :invoice_items
  many_to_one :shipment, join_table: :shipped_items
end
