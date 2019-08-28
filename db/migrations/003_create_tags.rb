class CreateTags < Sequel::Migration
  def up
    create_table :tags do
      primary_key :id

      String :name, size: 16, null: false
      String :description
      String :taxonomy, size: 256
      DateTime :created_at

      constraint name_min_length: char_length(name) > 2
    end
  end

  def down
    drop_table :tags
  end
end