class QuoteRequest < Sequel::Model
  many_to_one :user
end
