class CreateAddresses < Sequel::Migration
  def up
    create_table :addresses do
      primary_key :id
      foreign_key :user_id, :users

      TrueClass :is_invoice_addr, null: false
      String :first_line, null: false
      String :second_line
      String :third_line
      String :city, null: false
      String :state, size: 2, null: false
      String :country, size: 2, null: false
      DateTime :created_at, null: false
    end
  end

  def down
    drop_table :addresses
  end
end