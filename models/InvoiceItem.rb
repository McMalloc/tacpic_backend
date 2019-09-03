class InvoiceItem < Sequel::Model
  many_to_one :invoice
  many_to_one :order_item
end
