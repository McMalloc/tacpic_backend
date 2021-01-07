class Variant < Sequel::Model
  many_to_many :tags, join_table: :taggings
  many_to_many :lists, join_table: :favs
  many_to_one :graphic
  one_to_many :versions

  def get_pdf
    File.open("#{ENV['APPLICATION_BASE']}/files/#{self.current_file_name}-PRINT-merged.pdf").read
  end

  def latest_version
    Version
        .where(variant_id: self.id)
        .order_by(:created_at)
        .limit(1)
        .last
  end

  def contributors
    User
          .select(:display_name, :id)
          .where(id: self.versions.map { |version| version.user_id }.uniq)
          .map(&:values)
  end

  def get_brf
    File.open("#{ENV['APPLICATION_BASE']}/files/#{self.current_file_name}-BRAILLE.brf").read
  end

  def get_rtf
    File.open("#{ENV['APPLICATION_BASE']}/files/#{self.current_file_name}-RICHTEXT.rtf").read
  end

  def get_zip
    name = "#{ENV['APPLICATION_BASE']}/files/#{self.current_file_name}.zip"

    unless File.exist? name
      Zip::File.open(name, Zip::File::CREATE) do |zipfile|
        zipfile.add(self.current_file_name + "__braille.brf", "#{ENV['APPLICATION_BASE']}/files/#{self.current_file_name}-BRAILLE.brf")
        zipfile.add(self.current_file_name + "__graphic.pdf", "#{ENV['APPLICATION_BASE']}/files/#{self.current_file_name}-PRINT-merged.pdf")
        zipfile.add(self.current_file_name + "__text.rtf", "#{ENV['APPLICATION_BASE']}/files/#{self.current_file_name}-RICHTEXT.rtf")
      end
    end

    File.open(name).read
  end
end