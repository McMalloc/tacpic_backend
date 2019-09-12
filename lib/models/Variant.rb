class Variant < Sequel::Model
  many_to_many :variants, join_table: :taggings
  many_to_many :lists, join_table: :favs
  many_to_one :graphic
  one_to_many :versions

  def after_save
    super
    self.add_version number: 0
  end
end