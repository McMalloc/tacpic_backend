class CreateFrontendErrors < Sequel::Migration
  def up
    create_table :frontend_errors do
      primary_key :id
      String :user_agent
      String :platform
      String :type
      String :frontend_version
      String :backend_version
      String :message
      String :stacktrace
      String :ip_hash

      DateTime :created_at
    end
  end

  def down
    drop_table? :frontend_errors
  end
end
