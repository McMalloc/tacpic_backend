class CreateTaggings < Sequel::Migration
  def up
    create_table :taggings do
      primary_key :id
      foreign_key :tag_id, :tags
      foreign_key :variant_id, :variants
      foreign_key :user_id, :users

      DateTime :created_at

      # primary_key [:tag_id, :variant_id, :user_id], name: :tagging_pk
    end
  end

  def down
    drop_table? :taggings
  end
end