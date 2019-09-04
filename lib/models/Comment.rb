class Comment < Sequel::Model
  many_to_one :user
  many_to_one :version
end