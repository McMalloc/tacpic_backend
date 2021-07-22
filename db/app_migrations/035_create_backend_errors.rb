class CreateBackendErrors < Sequel::Migration
  def up
    create_table :backend_errors do
      primary_key :id
      String :method
      String :path
      String :params
      String :frontend_version
      String :backend_version
      String :type
      String :backtrace
      String :message

      DateTime :created_at
    end
  end

  def down
    drop_table? :backend_errors
  end
end
