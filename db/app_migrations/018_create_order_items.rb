class CreateOrderItems < Sequel::Migration
  def up
    create_table :order_items do
      primary_key :id
      foreign_key :order_id, :orders

      String :product_id, null: false
      Integer :content_id
      String :description
      Integer :status, null: false, default: 1
      Integer :quantity, null: false, default: 1
      Integer :net_price
      Integer :gross_price
      Integer :weight
      TrueClass :requires_antikink, default: false # "Knickschutz"
      TrueClass :with_braille, default: true
      DateTime :created_at, null: false
    end
  end

  def down
    drop_table? :order_items
  end
end