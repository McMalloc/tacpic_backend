class CreateUserLayouts < Sequel::Migration
  def up
    create_table :user_layouts do
      primary_key :id
      foreign_key :user_id

      String :name, size: 256
      DateTime :created_at
      String :layout, text: true
    end
  end

  def down
    # You can use raw SQL if you need to
    self << 'DROP TABLE user_layouts'
  end
end