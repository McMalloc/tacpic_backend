class User < Sequel::Model
  one_to_many :addresses
  one_to_many :orders
  one_to_many :user_layouts
  many_to_many :tags, join_table: :taggings
  one_to_many :versions
  one_to_many :annotations
  one_to_many :comments
  one_to_many :downloads
  one_to_many :lists
end
