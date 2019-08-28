class CreatePayments < Sequel::Migration
  def up
    create_table :payments do
      primary_key :id

      Integer :user_id # not not null, maybe the payment was made from an unknown account
      Integer :invoice_id # not not null, maybe there was a misguided transaction
      BigDecimal :base_price, null: false, size: [10, 4]
      String :service # what information is being transmitted when a payment arrives?
      String :payed_by
      DateTime :created_at
    end
  end

  def down
    drop_table :payments
  end
end