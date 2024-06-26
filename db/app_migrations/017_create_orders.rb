require_relative '../../constants'

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

      Integer :status, null: false, default: CONSTANTS::ORDER_STATUS::RECEIVED
      # 0: ---
      # 1: eingenagen
      # 2: übermittelt an Produktionspartner
      # 3: produziert, wird dem Versand übergeben
      # 4? versendet und bezahlt

      String :comment, text: true
      String :idempotency_key, null: false, unique: true # TODO: sollte primary key sein
      DateTime :created_at
    end
  end

  def down
    drop_table? :orders, cascade: true
  end
end
