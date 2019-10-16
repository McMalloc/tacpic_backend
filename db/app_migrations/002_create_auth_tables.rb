require 'rodauth/migrations'

Sequel.migration do
  up do
    extension :date_arithmetic

    db = self

    deadline_opts = proc do |days|
      if database_type == :mysql
        {:null => false}
      else
        {:null => false, :default => Sequel.date_add(Sequel::CURRENT_TIMESTAMP, :days => days)}
      end
    end

    # Used by the password reset feature
    create_table(:account_password_reset_keys) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      String :key, :null => false
      DateTime :deadline, deadline_opts[1]
      DateTime :email_last_sent, :null => false, :default => Sequel::CURRENT_TIMESTAMP
    end

    # Used by the jwt refresh feature
    create_table(:account_jwt_refresh_keys) do
      primary_key :id, :type => :Bignum
      foreign_key :account_id, :users, :type => :Bignum
      String :key, :null => false
      DateTime :deadline, deadline_opts[1]
    end

    # Used by the account verification feature
    create_table(:account_verification_keys) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      String :key, :null => false
      DateTime :requested_at, :null => false, :default => Sequel::CURRENT_TIMESTAMP
      DateTime :email_last_sent, :null => false, :default => Sequel::CURRENT_TIMESTAMP
    end

    # Used by the verify login change feature
    create_table(:account_login_change_keys) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      String :key, :null => false
      String :login, :null => false
      DateTime :deadline, deadline_opts[1]
    end

    # Used by the remember me feature
    create_table(:account_remember_keys) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      String :key, :null => false
      DateTime :deadline, deadline_opts[14]
    end

    # Used by the lockout feature
    create_table(:account_login_failures) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      Integer :number, :null => false, :default => 1
    end
    create_table(:account_lockouts) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      String :key, :null => false
      DateTime :deadline, deadline_opts[1]
      DateTime :email_last_sent
    end

    # Used by the email auth feature
    create_table(:account_email_auth_keys) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      String :key, :null => false
      DateTime :deadline, deadline_opts[1]
      DateTime :email_last_sent, :null => false, :default => Sequel::CURRENT_TIMESTAMP
    end

    # Used by the password expiration feature
    create_table(:account_password_change_times) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      DateTime :changed_at, :null => false, :default => Sequel::CURRENT_TIMESTAMP
    end

    # Used by the account expiration feature
    create_table(:account_activity_times) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      DateTime :last_activity_at, :null => false
      DateTime :last_login_at, :null => false
      DateTime :expired_at
    end

    # Used by the single session feature
    create_table(:account_session_keys) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      String :key, :null => false
    end

    # Used by the otp feature
    create_table(:account_otp_keys) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      String :key, :null => false
      Integer :num_failures, :null => false, :default => 0
      Time :last_use, :null => false, :default => Sequel::CURRENT_TIMESTAMP
    end

    # Used by the recovery codes feature
    create_table(:account_recovery_codes) do
      foreign_key :id, :users, :type => :Bignum
      String :code
      primary_key [:id, :code]
    end

    # Used by the sms codes feature
    create_table(:account_sms_codes) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      String :phone_number, :null => false
      Integer :num_failures
      String :code
      DateTime :code_issued_at, :null => false, :default => Sequel::CURRENT_TIMESTAMP
    end

    # -----

    create_table(:account_password_hashes) do
      foreign_key :id, :users, :primary_key => true, :type => :Bignum
      String :password_hash, :null => false
    end
    Rodauth.create_database_authentication_functions(self)

    # Used by the disallow_password_reuse feature
    create_table(:account_previous_password_hashes) do
      primary_key :id, :type => :Bignum
      foreign_key :account_id, :users, :type => :Bignum
      String :password_hash, :null => false
    end
    Rodauth.create_database_previous_password_check_functions(self)
  end

  down do
    drop_table(:account_sms_codes,
               :account_recovery_codes,
               :account_otp_keys,
               :account_session_keys,
               :account_activity_times,
               :account_password_change_times,
               :account_email_auth_keys,
               :account_lockouts,
               :account_login_failures,
               :account_remember_keys,
               :account_login_change_keys,
               :account_verification_keys,
               :account_jwt_refresh_keys,
               :account_password_reset_keys)

    Rodauth.drop_database_previous_password_check_functions(self)
    Rodauth.drop_database_authentication_functions(self)
    drop_table(:account_previous_password_hashes, :account_password_hashes)
  end
end