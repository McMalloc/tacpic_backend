class CreateUserLayouts < Sequel::Migration
  def up
    create_table :user_layouts do
      primary_key :id
      int :user_id
      text :name
      DateTime :created_at
      longtext :layout
    end
  end

  def down
    # You can use raw SQL if you need to
    self << 'DROP TABLE user_layouts'
  end
end