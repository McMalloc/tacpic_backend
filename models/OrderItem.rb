class OrderItem < Sequel::Model
  many_to_many :invoice, join_table: :invoice_item
  many_to_one :order
  one_to_many :invoice_items
  many_to_one :shipment, join_table: :shipped_items
  many_to_many :products

  def before_save
    if self.product_id == 'graphic' || self.product_id == 'graphic_nobraille'
      variant = Variant[self.content_id]
      self.description = "#{variant.graphic.title} (#{variant.title})\nv#{variant.latest_version.id}, #{variant.graphic_no_of_pages} Schwellpapierseite(n)"
    elsif self.product_id == 'postage' || self.product_id == 'postage_reduced'
      self.description = "Versand"
    elsif self.product_id == 'packaging'
      self.description = "Verpackung"
    end
  end
end
