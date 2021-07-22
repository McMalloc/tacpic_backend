class CreateGraphics < Sequel::Migration
  def up
    create_table :graphics do
      # uuid :id, primary_key: true
      primary_key :id
      foreign_key :user_id; :users

      String :title, size: 256, null: false
      # String :description, text: true
      DateTime :created_at

      full_text_index [:title]
    end
  end

  def down
    drop_table? :graphics
  end
end
