class Variant < Sequel::Model
  many_to_many :variants, join_table: :taggings
  many_to_many :lists, join_table: :favs
  many_to_one :graphic
end