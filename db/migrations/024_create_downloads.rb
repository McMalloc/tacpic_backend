class CreateDownloads < Sequel::Migration
  def up
    create_table :downloads do
      primary_key :id
      String :version_id, size: 16
      foreign_key [:version_id], :versions
      foreign_key :user_id, :users # issued to

      String :url, null: false # index because will be looked up when user calls url
      DateTime :created_at, null: false

      index :url
    end
  end

  def down
    drop_table :downloads
  end
end