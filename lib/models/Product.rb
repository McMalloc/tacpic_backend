class Product < Sequel::Model
  many_to_many :orders, join_table: :ordered_items
end
