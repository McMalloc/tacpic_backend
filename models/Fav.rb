class Fav < Sequel::Model
  many_to_one :list
  many_to_one :variant
end