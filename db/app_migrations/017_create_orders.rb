class CreateOrders < Sequel::Migration
  def up
    create_table :orders do
      primary_key :id
      foreign_key :user_id, :users
      foreign_key :address_id, :addresses
      # foreign_key :invoice_address_id, :addresses

      TrueClass :test, default: false
      Integer :total
      Integer :weight
      Integer :status, null: false, default: 1
      String :comment, text: true
      DateTime :created_at
    end
  end

  def down
    drop_table :orders
  end
end