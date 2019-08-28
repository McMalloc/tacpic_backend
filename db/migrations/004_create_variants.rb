class CreateVariants < Sequel::Migration
  def up
    create_table :variants do
      primary_key :id
      foreign_key :user_id
      foreign_key :graphic_id
      String :title, size: 256, null: false
      String :description
      String :long_description
      DateTime :created_at
    end
  end

  def down
    drop_table :variants
  end
end