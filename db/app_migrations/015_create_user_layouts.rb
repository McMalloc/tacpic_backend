class CreateUserLayouts < Sequel::Migration
  def up
    create_table :user_layouts do
      foreign_key :user_id, :users

      String :name, size: 256
      String :layout, text: true

      DateTime :created_at

      primary_key [:user_id, :name], name: :user_layout_pk
    end
  end

  def down
    # You can use raw SQL if you need to
    drop_table? :user_layouts
  end
end