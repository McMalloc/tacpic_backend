class CreateGraphics < Sequel::Migration
  def up
    create_table :graphics do
      primary_key :id

      String :title, size: 256, null: false
      String :description, text: true
      DateTime :created_at

      full_text_index [:title, :description]
    end
  end

  def down
    if @db.table_exists?(:graphics)
      drop_table :graphics
    end
  end
end