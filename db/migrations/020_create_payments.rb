class CreatePayments < Sequel::Migration
  def up
    create_table :payments do
      primary_key :id

      Integer :user_id # no key or required, since some payments cannot be matched
      Integer :invoice_id
      Integer :amount
      # String :currency, size: 3
      String :service # what infos does the PSP transmit?
      DateTime :created_at
    end
  end

  def down
    drop_table :payments
  end
end