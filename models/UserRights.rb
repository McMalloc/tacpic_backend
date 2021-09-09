class UserRights < Sequel::Model
  one_to_one :user
end