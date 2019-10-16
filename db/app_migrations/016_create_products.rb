class CreateProducts < Sequel::Migration
  def up
    create_table :products do
      primary_key :id

      BigDecimal :base_price, null: false, size: [10, 4] # rounding with SQL: ROUND(number, 2)
      String :identifier, size: 256, null: false
      String :desc_identifier, size: 256, null: false
      DateTime :created_at
    end
  end

  def down
    drop_table :products
  end
end