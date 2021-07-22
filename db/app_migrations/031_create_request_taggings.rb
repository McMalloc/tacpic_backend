class CreateRequestTaggings < Sequel::Migration
  def up
    create_table :request_taggings do
      foreign_key :tag_id, :tags
      foreign_key :request_id, :requests
      foreign_key :user_id, :users

      DateTime :created_at

      primary_key [:tag_id, :request_id, :user_id], name: :request_tagging_pk
    end
  end

  def down
    drop_table? :request_taggings
  end
end