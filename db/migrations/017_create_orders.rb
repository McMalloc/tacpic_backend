class CreateOrders < Sequel::Migration
  def up
    create_table :orders do
      primary_key :id
      foreign_key :user_id
      foreign_key :address_id

      Integer :status, null: false, default: 1
      String :comment, text: true
      DateTime :created_at
    end
  end

  def down
    drop_table :orders
  end
end