class CreateOrderItems < Sequel::Migration
  def up
    create_table :order_items do
      primary_key :id
      foreign_key :order_id, :orders
      foreign_key :product_id, :products

      Integer :content_id, null: false
      Integer :status, null: false, default: 1
      Integer :quantity, null: false, default: 1
      BigDecimal :base_price, null: false, size: [10, 4]
      DateTime :created_at, null: false
    end
  end

  def down
    drop_table :order_items
  end
end