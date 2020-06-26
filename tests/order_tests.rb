require_relative "./test_helper"

describe "Calculations" do
  it 'should correctly calculate prices and taxes' do
    price = GraphicPriceCalculator.new(Variant[$fixture1_variant_id].values, true)
    # 3 graphic pages, 2 braille pages
    # swell_a4,   87
    # swell_a3,   102
    # emboss_a4,  61
    assert_equal 383, price.net
    assert_equal 410, price.gross
    assert_equal 261, price.net_graphics_only
    assert_equal 280, price.gross_graphics_only
  end
end

describe "Orders" do
  let(:order_renderer) {ERB.new File.read('tests/test_data/new_order.json.erb')}

  before do
    header 'Authorization', 'Bearer ' + $token
    header 'Content-Type', 'application/json'
  end

  after do
    pp last_response
  end

  it 'should reject an order from an invalid user' do
    header 'Authorization', 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhY2NvdW50X2lkIjoxfQ.qYEKc7Tw2Hopck9OgHggEzA5P0KDZuBxa4i9QOtYxys'
    prev_nr_of_orders = Order.all.count
    post 'orders', order_renderer.result_with_hash(nr_items: 1, quantity: [1], content_ids: [$fixture1_version_id], comment: "Ich bin verboten")
    assert_equal 400, last_response.status
    assert_equal prev_nr_of_orders, Order.all.count
  end

  it 'should reject an empty order' do
    prev_nr_of_orders = Order.all.count
    post 'orders', order_renderer.result_with_hash(nr_items: 0, quantity: [], content_ids: [], comment: "Ich bin leer")
    assert_equal 409, last_response.status
    assert_equal prev_nr_of_orders, Order.all.count
  end

  it "should create a new order" do
    post 'orders', order_renderer.result_with_hash(nr_items: 3, quantity: [1,3,3], version_id: [$fixture1_version_id, $fixture2_version_id, $fixture3_version_id], comment: "Ich bin ok")
    assert_equal 201, last_response.status
    response = get_body(last_response)
    assert_equal Order[response['order']['id']].total, 573
  end
end
