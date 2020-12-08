class CreateVersions < Sequel::Migration
  def up
    create_table :versions do
      primary_key :id
      String :hash, size: 32, index: true
      foreign_key :user_id, :users
      foreign_key :variant_id, :variants

      String :document, mediumtext: true # max. 16MB
      String :file_name 
      String :change_message
      column :created_at, 'timestamp(6)'
    end
  end

  def down
    drop_table :versions
  end
end