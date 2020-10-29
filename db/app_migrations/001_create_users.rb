Sequel.migration do
  up do
    create_table :account_statuses do
      Integer :id, :primary_key => true
      String :name, :null => false, :unique => true
    end
    from(:account_statuses).import([:id, :name], [[1, 'Unverified'], [2, 'Verified'], [3, 'Closed']])

    create_table :users do
      primary_key :id

      # from rodauth
      foreign_key :status_id, :account_statuses, :null => false, :default => 1
      constraint :valid_email, :email => /^[^,;@ \r\n]+@[^,@; \r\n]+\.[^,@; \r\n]+$/
      index :email, :unique => true, :where => {:status_id => [1, 2]}
      String :email, null: false
      # defined in accounts

      # String :password, size: 16, null: false, fixed: true
      # String :salt, size: 8, null: false, fixed: true
      String :display_name, size: 32, :unique => true
      TrueClass :newsletter_active, :default => false
      Integer :role, null: false, default: 0
      DateTime :created_at
    end
  end

  down do
    # if @db.table_exists?(:users)
      drop_table :users
    # end
    # if @db.table_exists?(:account_statuses)
      drop_table :account_statuses
    # end
  end
end