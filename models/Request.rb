class Request < Sequel::Model
  many_to_one :user
end
