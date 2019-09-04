class CreateTags < Sequel::Migration
  def up
    create_table :tags do
      # primary_key :id
      foreign_key :user_id, :users

      String :name, size: 255
      primary_key [:name]

      String :description
      Integer :taxonomy # domain value
      DateTime :created_at

      index :name
      # constraint name_min_length: char_length(:name) > 2
    end
  end

  def down
    drop_table :tags
  end
end