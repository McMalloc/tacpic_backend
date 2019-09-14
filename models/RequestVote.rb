class RequestVote < Sequel::Model
  many_to_one :user
  many_to_one :request
end
