class Account < Sequel::Model
  one_to_one :user
end
