class Proposal < Sequel::Model
  many_to_one :request
end
