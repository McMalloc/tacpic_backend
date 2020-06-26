class Order < Sequel::Model
  many_to_one :user
  one_to_many :shipped_items
  one_to_one :invoice
  one_to_many :order_items

  def finalise
    # acc_price = 0
    # acc_weight = 0
    # requires_antikink = false
    # postage_id = nil
    #
    # self.order_items.each do |order_item|
    #   acc_price += order_item.price
    #   acc_weight += order_item.weight
    #   requires_antikink = requires_antikink || order_item.requires_antikink
    # end
    #
    # # TODO wenn über 1000g, zweite Sendung
    #
    # postage_weight = 0
    # if requires_antikink
    #   postage_weight += Fix.weights('antikink')
    #   if acc_weight < 500
    #     postage_id = 'buewa500'
    #     postage_weight += Fix.weights('packaging_a3')
    #   else
    #     postage_id = 'buewa1000'
    #     postage_weight += Fix.weights('packaging_a3_max')
    #   end
    # else
    #   if acc_weight < 500
    #     postage_id = 'maxi'
    #     postage_weight += Fix.weights('packaging_a4')
    #   else
    #     postage_id = 'buewa1000'
    #     postage_weight += Fix.weights('packaging_a3')
    #   end
    # end
    #
    # postage_item = self.add_order_item(
    #     product_id: 'postage', # postage
    #     content_id: postage_id,
    #     quantity: 1,
    #     weight: postage_weight,
    #     price: requires_antikink ? Fix.base_price("shipping_a3") : Fix.base_price("shipping_a3")
    # )
    #
    # acc_price += postage_item.price
    # acc_weight += postage_item.weight
    #
    # self.update(
    #     total: acc_price,
    #     weight: acc_weight
    # )
  end
end
