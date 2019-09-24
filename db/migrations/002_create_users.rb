class CreateUsers < Sequel::Migration
  def up
    create_table :users do
      primary_key :id

      # defined in accounts
      # String :email, null: false
      # String :password, size: 16, null: false, fixed: true
      # String :salt, size: 8, null: false, fixed: true
      String :display_name, size: 16
      Integer :role, null: false
      DateTime :created_at
    end
  end

  def down
    drop_table :users
  end
end