class Graphic < Sequel::Model
  one_to_many :variants
  many_to_one :user

  def create

  end

  def after_save
    super
    self.add_variant title: self.title
  end

  # creates request
  def create_request

  end
end