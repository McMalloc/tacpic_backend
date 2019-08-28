class CreateComments < Sequel::Migration
  def up
    create_table :comments do
      primary_key :id
      foreign_key :user_id
      foreign_key :version_id
      Integer :state, null: false
      String :content, text: true
      DateTime :created_at
    end
  end

  def down
    drop_table :comments
  end
end