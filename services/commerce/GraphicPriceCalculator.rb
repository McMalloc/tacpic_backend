class GraphicPriceCalculator
  attr_accessor :tax_rate

  @@prices = {}
  CSV.parse(File.read('services/commerce/base_prices.csv'), headers: true).each do |row|
    @@prices[row[0].strip.to_sym] = row[1].to_i
  end

  def initialize(variant, reduced)
    @variant = variant
    @tax_rate = reduced ? 0.07 : 0.16 # TODO woanders speichern
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
    unless net_only
      price += @tax_rate * price
    end
    return price
  end
end