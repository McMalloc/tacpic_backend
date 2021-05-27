class Order < Sequel::Model
  many_to_one :user
  one_to_many :shipped_items
  one_to_one :invoice
  one_to_many :order_items

  # get a hash to finalise order via link
  def get_hash
    Digest::MD5.hexdigest self.created_at.to_s + self.id.to_s
  end

  def get_finalise_link
    "#{ENV['API_HOST']}/orders/#{self.id}/finalise?hash=#{self.get_hash}"
  end
end
