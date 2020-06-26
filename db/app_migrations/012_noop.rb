class CreateBasePrices < Sequel::Migration
  def up
    # create_table :base_prices do
    #   String :identifier, size: 256, primary_key: true
    #
    #   Integer :base_price, null: false, size: [10, 4] # rounding with SQL: ROUND(number, 2)
    #   DateTime :created_at
    # end
  end

  def down
    # if @db.table_exists?(:base_prices)
    #   drop_table :base_prices
    # end
  end
end