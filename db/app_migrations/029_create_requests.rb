class CreateRequests < Sequel::Migration
  def up
    create_table :requests do
      primary_key :id
      foreign_key :user_id, :users
      String :title
      String :description, text: true
      String :file_url
      Integer :state, default: 0, null: false

      DateTime :created_at
    end
  end

  def down
    drop_table? :requests
  end
end