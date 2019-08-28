class CreatePayments < Sequel::Migration
  def up
    create_table :payments do
      primary_key :id
      foreign_key :invoice_id
      foreign_key :order_id

      Integer :status, null: false, default: 1
      String :comment, text: true
      DateTime :created_at
    end
  end

  def down
    drop_table :payments
  end
end