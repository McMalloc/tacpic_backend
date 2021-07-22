class CreateInvoices < Sequel::Migration
  def up
    create_table :invoices do
      primary_key :id
      foreign_key :address_id, :addresses
      foreign_key :order_id, :orders

      String :voucher_id
      String :voucher_filename
      String :invoice_number
      Integer :status, null: false, default: 1
      String :comment, text: true
      DateTime :created_at, null: false
    end
  end

  def down
    drop_table? :invoices
  end
end