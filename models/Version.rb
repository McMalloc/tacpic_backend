require 'digest'
require "zlib"

class Version < Sequel::Model
  many_to_one :user
  many_to_one :variant
  one_to_many :versions
  one_to_many :comments

  def before_save
    self.change_message = "..." # TODO: Diff der Objekte im document?
    self.hash = Digest::MD5.hexdigest self.document # TODO compress serialised document
  end
end