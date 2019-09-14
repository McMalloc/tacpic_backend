class CreateTaggings < Sequel::Migration
  def up
    create_table :taggings do
      foreign_key :tag_name, :tags, type: 'varchar(255)'
      foreign_key :variant_id, :variants
      foreign_key :user_id, :users

      DateTime :created_at

      primary_key [:tag_name, :variant_id, :user_id], name: :tagging_pk
    end
  end

  def down
    drop_table :taggings
  end
end