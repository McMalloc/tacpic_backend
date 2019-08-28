class Graphic < Sequel::Model
  one_to_many :variants
end