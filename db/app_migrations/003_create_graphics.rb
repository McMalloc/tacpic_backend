class CreateGraphics < Sequel::Migration
  def up
    create_table :graphics do
      primary_key :id
      # foreign_key :user_id, :users # versions are linked to users

      String :title, size: 256, null: false
      # String :description, text: true # variants should specify content
      DateTime :created_at

      full_text_index :title
      # full_text_index :description
    end
  end

  def down
    drop_table :graphics
  end
end