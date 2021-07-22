class InternetmarkeTransactions < Sequel::Migration
  def up
    create_table :internetmarke_transactions do
      primary_key :id
      foreign_key :invoice_id, :invoices # may be null
      foreign_key :shipment_id, :shipments # may be null
      String :shop_order_id, null: false
      String :voucher_id, null: false
      Integer :balance, null: false
      Integer :ppl_id, null: false
      Integer :amount, null: false
      TrueClass :is_credit, null: false, default: false # a credit transaction raises :balance by :amount

      DateTime :created_at
    end
  end

  def down
    drop_table? :internetmarke_transactions
  end
end
