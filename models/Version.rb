class Version < Sequel::Model
  many_to_one :user
  many_to_one :graphics
  one_to_many :versions
  one_to_many :comments

  def before_update
    self.hash = self.document.length # calculate hash from document
  end
end