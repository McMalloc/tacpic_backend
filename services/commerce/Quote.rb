class Quote
  attr_accessor :order_items, :packaging_item, :weight
  include CommerceData

  def initialize(order_items, variants)
    @order_items = order_items
    @variants = variants
    @weight = 0

    @order_items.each_with_index do |item, _index|
      corresponding_variant = @variants.find { |variant| variant[:id] == item.content_id }
      corresponding_variant.nil? && next
      
      case item.product_id
      when 'graphic'
        price = PriceCalculator.new(corresponding_variant, get_product(item.product_id)[:reduced_vat] == 'true')
        item.net_price = price.net
        item.gross_price = price.gross
        item.weight = corresponding_variant[:graphic_no_of_pages] * get_weight("swell_#{corresponding_variant[:graphic_format]}")
        +corresponding_variant[:braille_no_of_pages] * get_weight("emboss_#{corresponding_variant[:braille_format]}")
      when 'graphic_nobraille'
        price = PriceCalculator.new(corresponding_variant, get_product(item.product_id)[:reduced_vat])
        item.net_price = price.net_graphics_only
        item.gross_price = price.gross_graphics_only
        item.weight = corresponding_variant[:graphic_no_of_pages] * get_weight("swell_#{corresponding_variant[:graphic_format]}")
      end

      @weight += item.weight
    end

    @postage_item = postage_item
    @packaging_item = packaging_item
  end

  def vat
    amount = @order_items.inject(0) do |sum, item|
      !get_product(item.product_id)[:reduced_vat] ? item.gross_price - item.net_price + sum : sum
    end
    @postage_item.product_id == 'postage' && amount += @postage_item.gross_price - @postage_item.net_price
    amount
  end

  def reduced_vat
    amount = @order_items.inject(0) do |sum, item|
      get_product(item.product_id)[:reduced_vat] ? item.gross_price - item.net_price + sum : sum
    end
    @postage_item.product_id == 'postage_reduced' && amount += @postage_item.gross_price - @postage_item.net_price
    amount
  end

  def net
    amount = @order_items.inject(0) { |sum, item| item.net_price * item.quantity + sum }
    amount += @postage_item.net_price
  end

  def gross
    amount = @order_items.inject(0) { |sum, item| item.gross_price * item.quantity + sum }
    amount += @postage_item.gross_price
  end

  # TODO: ab wann reduzierte vat?
  # Setuersatz für Verpackung und Versand nach teuerstem abrechnen
  def postage_item
    postage = OrderItem.new(
      product_id: 'postage_reduced',
      quantity: 1
    )

    postage_product_id = :gross
    antikink = requires_antikink?
    if antikink && @weight < get_postage(:buewa500)[:threshold]
      postage_product_id = :buewa500
    elsif antikink && @weight > get_postage(:buewa500)[:threshold]
      postage_product_id = :buewa1000
    end

    postage.gross_price = get_price(:shipping_general)
    postage.net_price = (postage.gross_price / (1 + get_taxrate(:de_reduced_vat) / 100.0)).round
    postage.content_id = get_postage(postage_product_id)[:pplId]
    postage
  end

  private

  def requires_antikink?
    @order_items.each_with_index do |item, _index|
      corresponding_variant = @variants.find { |variant| variant[:id] == item.content_id }
      next if corresponding_variant.nil?
      return true if corresponding_variant[:graphic_format] == 'a3'

      return true if item[:with_braille] && (corresponding_variant[:braille_format] == 'a3')
    end
    false
  end
end
