class CreateAddresses < Sequel::Migration
  def up
    create_table :addresses do
      primary_key :id
      foreign_key :user_id, :users

      # fields are corresponding to the specifications of DPAG's Internetmarke
      TrueClass :is_invoice_addr, null: false, default: false
      TrueClass :active, default: true
      String :street, null: false
      String :house_number, null: false
      String :company_name
      String :first_name
      String :last_name

      String :additional
      String :city, null: false
      String :zip, null: false
      String :state
      String :country, size: 3, default: 'DEU' # ISO 3166-1 alpha-3
      DateTime :created_at, null: false
    end
  end

  def down
    drop_table? :addresses
  end
end