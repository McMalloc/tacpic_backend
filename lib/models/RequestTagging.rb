class RequestTaggings < Sequel::Model
  many_to_one :request
  many_to_one :tag
  many_to_one :user
end
