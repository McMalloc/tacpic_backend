class CreateVersions < Sequel::Migration
  def up
    create_table :versions do
      String :id, size: 16 # hash
      foreign_key :user_id, :users
      foreign_key :variant_id, :variants

      Integer :number, null: false
      String :document, mediumtext: true # max. 16MB
      DateTime :created_at

      primary_key [:id]
    end
  end

  def down
    drop_table :versions
  end
end