class CreateAnnotations < Sequel::Migration
  def up
    create_table :annotations do
      primary_key :id
      foreign_key :user_id
      foreign_key :variants_id
      Integer :state, null: false
      String :content, text: true
      DateTime :created_at
    end
  end

  def down
    drop_table :annotations
  end
end