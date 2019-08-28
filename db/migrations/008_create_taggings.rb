class CreateTaggings < Sequel::Migration
  def up
    create_table :taggings do
      primary_key :id
      foreign_key :tag_id
      foreign_key :variant_id
      foreign_key :user_id
      DateTime :created_at
    end
  end

  def down
    drop_table :taggings
  end
end