class CreateRequests < Sequel::Migration
  def up
    create_table :requests do
      primary_key :id
      foreign_key :user_id
      String :title, size: 256, null: false
      String :description, text: true
      DateTime :created_at
    end
  end

  def down
    drop_table :requests
  end
end