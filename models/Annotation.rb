class Annotation < Sequel::Model
  many_to_one :user
  many_to_one :variant
end
