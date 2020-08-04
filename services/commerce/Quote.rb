class Quote
  attr_accessor :order_items, :postage_item, :packaging_item, :weight
  @@weights = {}
  CSV.parse(File.read('services/commerce/weights.csv'), headers: true).each do |row|
    @@weights[row[0].strip.to_sym] = row[1].to_i
  end
  @@prices = {}
  CSV.parse(File.read('services/commerce/base_prices.csv'), headers: true).each do |row|
    @@prices[row[0].strip.to_sym] = row[1].to_i
  end
  @@postages = {}
  CSV.parse(File.read('services/commerce/postage.csv'), headers: true).each do |row|
    @@postages[row[1].strip.to_sym] = {
        pplId: row[0].to_i,
        price: row[2].to_i,
        threshold: row[3].to_i
    }
  end
  @@products = {}
  CSV.parse(File.read('services/commerce/products.csv'), headers: true).each do |row|
    @@products[row[0].strip.to_sym] = {
        customisable: row[0].to_i,
        reduced_vat: row[2].to_i
    }
  end

  # Variant.where(id: [...order_items]).select(:title).all
  def initialize(order_items, variants)
    @order_items = order_items
    @variants = variants
    @weight = 0

    @order_items.each_with_index do |item, index|
      corresponding_variant = @variants.find {|variant|variant[:id] == item.content_id}
      if item.product_id == 'graphic'
        price = GraphicPriceCalculator.new(corresponding_variant, @@products[item.product_id.to_sym][:reduced_vat])
        item.net_price = price.net
        item.gross_price = price.gross
        item.weight = corresponding_variant[:graphic_no_of_pages] * @@weights["swell_#{corresponding_variant[:graphic_format]}".to_sym]
        +corresponding_variant[:braille_no_of_pages] * @@weights["emboss_#{corresponding_variant[:braille_format]}".to_sym]
      elsif item.product_id == 'graphic_nobraille'
        price = GraphicPriceCalculator.new(corresponding_variant, @@products[item.product_id.to_sym][:reduced_vat])
        item.net_price = price.net_graphics_only
        item.gross_price = price.gross_graphics_only
        item.weight = corresponding_variant[:graphic_no_of_pages] * @@weights["swell_#{corresponding_variant[:graphic_format]}".to_sym]
      end

      @weight += item.weight
    end

    @postage_item = postage_item
    @packaging_item = packaging_item
  end

  def order_items
    @order_items
  end

  def vat
    amount = @order_items.inject(0) { |sum, item| !@@products[item.product_id.to_sym][:reduced_vat] ? item.gross_price - item.net_price + sum : sum }
    @postage_item.product_id == 'postage' && amount += @postage_item.gross_price - @postage_item.net_price
    # @packaging_item.product_id == 'packaging' && amount += @packaging_item.gross_price - @packaging_item.net_price
    return amount
  end

  def reduced_vat
    amount = @order_items.inject(0) { |sum, item| @@products[item.product_id.to_sym][:reduced_vat] ? item.gross_price - item.net_price + sum : sum }
    @postage_item.product_id == 'postage_reduced' && amount += @postage_item.gross_price - @postage_item.net_price
    # @packaging_item.product_id == 'packaging_reduced' && amount += @packaging_item.gross_price - @packaging_item.net_price
    return amount
  end

  def net
    amount = @order_items.inject(0) { |sum, item| item.net_price * item.quantity + sum }
    amount += @postage_item.net_price
    # amount += @packaging_item.net_price
  end

  def gross
    amount = @order_items.inject(0) { |sum, item| item.gross_price * item.quantity + sum }
    amount += @postage_item.gross_price
    # amount += @packaging_item.gross_price
  end

  # DEPRECATED
  # TODO
  # def packaging_item
  #   OrderItem.new(
  #       product_id: "packaging",
  #       quantity: 1,
  #       net_price: @@prices[:packaging],
  #       gross_price: @@prices[:packaging] * 1.07, # todo, s. unten
  #   )
  # end

  # TODO ab wann reduzierte vat?
  # Setuersatz für Verpackung und Versand nach teuerstem abrechnen
  def postage_item
    postage = OrderItem.new(
        product_id: 'postage_reduced',
        quantity: 1
    )

    postage_product_id = :gross
    antikink = requires_antikink?
    if antikink and @weight < @@postages[:buewa500][:threshold]
      postage_product_id = :buewa500
    elsif antikink and @weight > @@postages[:buewa500][:threshold]
      postage_product_id = :buewa1000
    end

    postage.net_price = @@prices[:shipping_general]
    # postage.gross_price = @@postages[postage_product_id][:price]
    postage.gross_price = (postage.net_price * 1.07).round # TODO no magic numbers
    postage.content_id = @@postages[postage_product_id][:pplId]
    return postage
  end

  private

  def requires_antikink?
    @order_items.each_with_index do |item, index|
      if @variants.find {|variant|variant[:id] == item.content_id}[:graphic_format] == "a3"
        return true
      end
      if item[:with_braille]
        if @variants.find {|variant|variant[:id] == item.content_id}[:braille_format] == "a3"
          return true
        end
      end
    end
    return false
  end
end

