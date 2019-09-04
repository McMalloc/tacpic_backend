class UserLayout < Sequel::Model
  many_to_one :user
end