class CreatePosts < Sequel::Migration
  def up
    create_table :posts do
      primary_key :id
      foreign_key :user_id, :users
      Integer :parent, index: true # null if op
      String :content, text: true

      DateTime :created_at
    end
  end

  def down
    drop_table? :posts
  end
end