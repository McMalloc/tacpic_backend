class User < Sequel::Model
  one_to_many :addresses
  one_to_many :orders
  one_to_many :user_layouts
  many_to_many :tags, join_table: :taggings
  one_to_many :versions # the method will not always be usable, i.e. if the corresponding graphic doesn't exist yet
  one_to_many :annotations
  one_to_many :comments
  one_to_many :downloads
  one_to_many :lists
  one_to_one :user_rights

  one_to_one :account

  def before_save
    # self[:display_name] = request.params['display_name']
    super
  end
end
