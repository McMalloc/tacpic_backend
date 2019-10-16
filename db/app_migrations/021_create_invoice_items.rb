class CreateInvoiceItems < Sequel::Migration
  def up
    create_table :invoice_items do
      foreign_key :order_item_id, :order_items
      foreign_key :invoice_id, :invoices
      primary_key [:order_item_id, :invoice_id], name: :invoice_items_pk

      Integer :quantity
      DateTime :created_at, null: false
      # constraint(:quantity){quantity > 1}
    end
  end

  def down
    drop_table :invoice_items
  end
end