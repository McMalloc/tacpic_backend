require_relative './test_helper'

describe 'Price Calculator' do
  it '1 a4 graphic' do
    variant = build :variant
    price = PriceCalculator.new variant, true
    assert_equal 390, price.gross
    assert_equal 364, price.net
  end

  it '1 a3 graphic' do
    variant = build :variant, graphic_format: 'a3'
    price = PriceCalculator.new variant, true
    assert_equal 690, price.gross
    assert_equal 645, price.net
  end
end
