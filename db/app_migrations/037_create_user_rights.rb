class UserRights < Sequel::Migration
  def up
    create_table :user_rights do
      primary_key :id
      foreign_key :user_id, :users, null: false
      TrueClass :can_order, default: true
      TrueClass :can_hide_variants, default: false
      TrueClass :can_view_admin, default: false
      TrueClass :can_edit_admin, default: false

      DateTime :changed_at
      DateTime :created_at
    end
  end

  def down
    drop_table? :user_rights
  end
end
