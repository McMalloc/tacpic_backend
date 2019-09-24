class Variant < Sequel::Model
  many_to_many :tags, join_table: :taggings
  many_to_many :lists, join_table: :favs
  many_to_one :graphic
  one_to_many :versions
end