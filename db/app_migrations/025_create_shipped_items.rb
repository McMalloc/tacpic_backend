class CreateShippedItems < Sequel::Migration
  def up
    create_table :shipped_items do
      foreign_key :order_item_id, :order_items
      foreign_key :shipment_id, :shipments
      primary_key [:order_item_id, :shipment_id], name: :shipped_items_pk

      Integer :quantity
      DateTime :created_at, null: false
    end
  end

  def down
    drop_table :shipped_items
  end
end