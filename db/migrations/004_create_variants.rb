class CreateVariants < Sequel::Migration
  def up
    create_table :variants do
      primary_key :id
      foreign_key :graphic_id, :graphics

      TrueClass :public, default: true
      String :title, null: false
      String :description, longtext: true
      String :long_description, longtext: true
      DateTime :created_at

      full_text_index [:title, :description, :long_description]
    end
  end

  def down
    drop_table :variants
  end
end