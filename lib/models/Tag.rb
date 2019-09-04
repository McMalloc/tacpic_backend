class Tag < Sequel::Model
  many_to_many :variants, join_table: :taggings
  many_to_many :users, join_table: :taggings
end
