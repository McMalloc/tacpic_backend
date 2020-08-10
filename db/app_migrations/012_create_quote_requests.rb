class CreateQuoteRequests < Sequel::Migration
  def up
    create_table :quote_requests do
      primary_key :id
      foreign_key :user_id; :users

      String :items
      String :comment
      String :answer_address
      Integer :status, default: 0
      DateTime :created_at
    end
  end

  def down
    if @db.table_exists?(:quote_requests)
      drop_table :quote_requests
    end
  end
end