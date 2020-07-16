class CreateShipments < Sequel::Migration
  def up
    create_table :shipments do
      primary_key :id
      foreign_key :address_id, :addresses
      foreign_key :order_id, :orders

      Integer :status, null: false, default: 1
      String :tracking_number
      String :voucher_filename
      String :voucher_id
      String :service
      DateTime :created_at, null: false
    end
  end

  def down
    drop_table :shipments
  end
end