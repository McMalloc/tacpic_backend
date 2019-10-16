class CreateApprovals < Sequel::Migration
  def up
    create_table :approvals do
      foreign_key :variant_id, :variants
      foreign_key :user_id, :users

      DateTime :created_at, null: false

      primary_key [:variant_id, :user_id], name: :approval_pk
    end
  end

  def down
    drop_table :approvals
  end
end