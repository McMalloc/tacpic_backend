class List < Sequel::Model
  many_to_one :user
  many_to_one :variants, join_table: :favs
end