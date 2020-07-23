class CreateOrders < Sequel::Migration
  def up
    create_table :orders do
      primary_key :id
      foreign_key :user_id, :users
      # foreign_key :invoice_id, :invoices
      # foreign_key :address_id, :addresses
      # foreign_key :invoice_address_id, :addresses

      TrueClass :test, default: false
      Integer :total_gross
      Integer :total_net
      String :payment_method, default: 'invoice'
      Integer :weight
      Integer :status, null: false, default: 0
      String :comment, text: true
      String :idempotency_key, null: false, unique: true # todo sollte primary key sein
      DateTime :created_at
    end
  end

  def down
    drop_table :orders
  end
end