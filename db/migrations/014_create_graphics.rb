class CreateGraphics < Sequel::Migration
  def up
    create_table :graphics do
      primary_key :id
      foreign_key :user_id
      String :title, size: 256, null: false
      String :description, text: true
      DateTime :created_at
    end
  end

  def down
    drop_table :graphics
  end
end