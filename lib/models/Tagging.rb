class Tagging < Sequel::Model
  many_to_one :variant
  many_to_one :tag
  many_to_one :user
end