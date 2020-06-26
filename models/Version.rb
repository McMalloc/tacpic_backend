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
    self.change_message = "..." # TODO: Diff der Objekte im document?
    self.hash = Digest::MD5.hexdigest self.document
    # self.document = Base64.encode64 Zlib::Deflate.deflate(self.document)
    # TODO compress serialised document
  end

  def inflate
    # self.document = Zlib::Inflate.inflate(Base64.decode64 self.document)
    self
  end

  def after_save
    super
    self.variant.update(
        file_name: DocumentProcessor.new(self).save_files
    )
  end
end