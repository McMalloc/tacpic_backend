class CreateFullfillments < Sequel::Migration
  def up
    create_table :fullfillments do
      primary_key :id
      foreign_key :user_id
      foreign_key :request_id
      foreign_key :graphic_id
      String :comment, text: true
      Integer :state
      DateTime :created_at
    end
  end

  def down
    drop_table :fullfillments
  end
end