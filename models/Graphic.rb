class Graphic < Sequel::Model
  one_to_many :variants
  many_to_one :user
end