class CreateProducts < Sequel::Migration
  def up
    create_table :products do
      String :identifier, size: 256, primary_key: true
      # foreign_key :base_price_identifier, :base_prices, type: String

      TrueClass :customisable, default: false
      TrueClass :reduced_vat, default: false
      DateTime :created_at
    end
  end

  def down
    drop_table? :products
  end
end