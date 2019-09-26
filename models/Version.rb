require 'digest'

class Version < Sequel::Model
  many_to_one :user
  many_to_one :variant
  one_to_many :versions
  one_to_many :comments

  def before_save
    self.hash = Digest::MD5.hexdigest self.document
  end
end