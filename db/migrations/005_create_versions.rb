class CreateVersions < Sequel::Migration
  def up
    create_table :versions do
      primary_key :id
      foreign_key :user_id
      foreign_key :variant_id
      Integer :number, null: false
      String :document, mediumtext: true # max. 16MB
      DateTime :created_at
    end
  end

  def down
    drop_table :versions
  end
end