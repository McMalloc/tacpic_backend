class CreateLists < Sequel::Migration
  def up
    create_table :lists do
      primary_key :id
      foreign_key :user_id, :users
      String :name
      DateTime :created_at
    end
  end

  def down
    drop_table? :lists
  end
end