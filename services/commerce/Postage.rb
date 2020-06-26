class Postage
  attr_accessor :price
  attr_accessor :weight
  attr_reader :variant

  def initialize(variant)
    @variant = variant
  end

  def calculate_weight

  end

  # def calculate_prize
  #   price = 0
  #   # price = Fix.base_price(self.product_id)
  #   price += @variant_values[:graphic_no_of_pages] * Fix.base_price("swell_#{@variant_values[:graphic_format]}")
  #   price += @variant_values[:braille_no_of_pages] * Fix.base_price("emboss_#{@variant_values[:braille_format]}")
  #
  #   price
  # end
  #
  # def calculate_weight
  #   weight = 0
  #   weight += variant[:graphic_no_of_pages] * Fix.weights("swell_#{variant[:graphic_format]}")
  #   if weight += variant[:braille_no_of_pages] * Fix.weights("emboss_#{variant[:braille_format]}")
  #
  #   weight
  #   self.price = price
  #   self.requires_antikink = variant[:graphic_format] == "a3" || variant[:braille_format] == "a3"
  #   self.weight = weight
  # end
end

