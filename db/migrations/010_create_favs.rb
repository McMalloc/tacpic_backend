class CreateFavs < Sequel::Migration
  def up
    create_table :favs do
      foreign_key :variant_id, :variants
      foreign_key :list_id, :lists
      primary_key [:variant_id, :list_id], name: :fav_pk

      DateTime :created_at
    end
  end

  def down
    drop_table :favs
  end
end