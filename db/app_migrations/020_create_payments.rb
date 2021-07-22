class CreatePayments < Sequel::Migration
  def up
    create_table :payments do
      primary_key :id

      foreign_key :user_id, :users # no key or required, since some payments cannot be matched
      foreign_key :invoice_id, :invoices
      Integer :amount
      String :currency, size: 3, default: 'EUR'
      String :method # what infos does the PSP transmit?
      DateTime :created_at
    end
  end

  def down
    drop_table? :payments
  end
end