class Variant < Sequel::Model
  many_to_many :tags, join_table: :taggings
  many_to_many :lists, join_table: :favs
  many_to_one :graphic
  one_to_many :versions

  def get_pdf
    File.open("#{ENV['APPLICATION_BASE']}/tacpic_backend/files/#{self.file_name}-PRINT-merged.pdf").read
  end

  def get_brf
    File.open("#{ENV['APPLICATION_BASE']}/tacpic_backend/files/#{self.file_name}-BRAILLE.brf").read
  end
end