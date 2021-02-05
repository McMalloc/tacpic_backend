class PriceCalculator
  include CommerceData
  attr_accessor :tax_rate

  def initialize(variant, reduced)
    @variant = variant
    @tax_rate = reduced ? get_taxrate(:de_reduced_vat) : get_taxrate(:de_vat)
  end

  def gross
    calculate_price false, false
  end

  def net
    calculate_price false, true
  end

  def gross_graphics_only
    calculate_price true, false
  end

  def net_graphics_only
    calculate_price true, true
  end

  def calculate_price(graphic_only, net_only)
    price = @@prices[:graphic]
    price += @variant[:graphic_no_of_pages] * @@prices["swell_#{@variant[:graphic_format]}".to_sym]
    unless graphic_only
      price += @variant[:braille_no_of_pages] * @@prices["emboss_#{@variant[:braille_format]}".to_sym]
    end
    if net_only
      # Bruttobetrag / (1 + Mehrwertsteuersatz) = Nettobetrag
      price /= 1 + @tax_rate / 100.0
    end
    return price.round
  end
end