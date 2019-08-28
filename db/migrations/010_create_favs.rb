class CreateFavs < Sequel::Migration
  def up
    create_table :favs do
      primary_key :id
      foreign_key :list_id
      foreign_key :variant_id
      DateTime :created_at
    end
  end

  def down
    drop_table :favs
  end
end