class Post < Sequel::Model
  many_to_one :user
  one_to_many :votes
end
