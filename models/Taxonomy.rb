class Taxonomy < Sequel::Model
  one_to_many :tags
end
