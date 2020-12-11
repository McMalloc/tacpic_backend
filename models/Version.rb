require 'digest'
require "zlib"
require "base64"
require_relative '../services/processor/DocumentProcessor'

class Version < Sequel::Model
  many_to_one :user
  many_to_one :variant
  one_to_many :versions
  one_to_many :comments

  def before_save
    super
    # self.document = Base64.encode64 Zlib::Deflate.deflate(self.document)
    # TODO compress serialised document
  end

  def inflate_document
    return Zlib::Inflate.inflate(Base64.decode64 self.document)
  end

  def after_save
    super
    if (self.file_name.nil?)
      self.update(file_name: DocumentProcessor.new(self).save_files)
      self.variant.update(current_file_name: self.file_name)
    end
  end
end