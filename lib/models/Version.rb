class Variant < Sequel::Model
  many_to_one :user
  many_to_one :graphics
  one_to_many :versions
  one_to_many :comments
end