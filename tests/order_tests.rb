require_relative "./test_helper"
require 'uuid'

uuid_gen = UUID.new

describe "Orders" do
  let(:order_renderer) {ERB.new File.read('tests/test_data/order_fixture.json.erb')}
  let(:order_renderer_no_items) {ERB.new File.read('tests/test_data/order_fixture_no_items.json.erb')}
  let(:order_renderer_with_invoice_address) {ERB.new File.read('tests/test_data/order_fixture_with_invoice_address.json.erb')}
  let(:order_renderer_with_new_addresses) {ERB.new File.read('tests/test_data/order_fixture_with_new_addresses.json.erb')}
  let(:order_renderer_with_no_addresses) {ERB.new File.read('tests/test_data/order_fixture_with_no_addresses.json.erb')}

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
    post 'orders', order_renderer_with_new_addresses.result_with_hash({variant1_id: $fixture1_variant_id,
                                                                       variant2_id: $fixture2_variant_id,
                                                                       variant3_id: $fixture3_variant_id,
                                                                       idempotency_key: uuid_gen.generate})
    assert_equal 400, last_response.status
    assert_equal prev_nr_of_orders, Order.all.count
  end

  it 'should reject an empty order' do
    prev_nr_of_orders = Order.all.count
    post 'orders', order_renderer_no_items.result_with_hash({shipping_address_id: $fixture_address_id,
                                                             idempotency_key: uuid_gen.generate})
    assert_equal 400, last_response.status
    assert_equal prev_nr_of_orders, Order.all.count
  end

  it 'should reject an order without addresses' do
    prev_nr_of_orders = Order.all.count
    post 'orders', order_renderer_with_no_addresses.result_with_hash({variant1_id: $fixture1_variant_id,
                                                                      variant2_id: $fixture2_variant_id,
                                                                      variant3_id: $fixture3_variant_id,
                                                                      idempotency_key: uuid_gen.generate})
    assert_equal 400, last_response.status
    assert_equal prev_nr_of_orders, Order.all.count
  end

  it 'should reject an order sent from the same form' do
    key = uuid_gen.generate
    post 'orders', order_renderer.result_with_hash({variant1_id: $fixture1_variant_id,
                                                    shipping_address_id: $fixture_address_id,
                                                                      variant2_id: $fixture2_variant_id,
                                                                      variant3_id: $fixture3_variant_id,
                                                                      idempotency_key: key})
    post 'orders', order_renderer.result_with_hash({variant1_id: $fixture1_variant_id,
                                                    shipping_address_id: $fixture_address_id,
                                                                      variant2_id: $fixture2_variant_id,
                                                                      variant3_id: $fixture3_variant_id,
                                                                      idempotency_key: key})
    assert_equal 409, last_response.status
  end

  it "should create a new order" do
    nr_of_addresses = Address.all.count
    nr_of_orders = Order.where(user_id: $test_user_id).count
    post 'orders', order_renderer.result_with_hash({shipping_address_id: $fixture_address_id,
                                                    variant1_id: $fixture1_variant_id,
                                                    variant2_id: $fixture2_variant_id,
                                                    variant3_id: $fixture3_variant_id,
                                                    idempotency_key: uuid_gen.generate})
    response = JSON.parse(last_response.body)
    assert_equal 201, last_response.status
    # assert_equal $fixture_address_id, Shipment.where(order_id: response['id']).address_id
    assert_equal $fixture_address_id, Order[response['id']].invoice.address_id
    assert_equal nr_of_orders + 1, Order.where(user_id: $test_user_id).count

    post 'orders', order_renderer_with_invoice_address.result_with_hash({shipping_address_id: $fixture_address_id,
                                                                         invoice_address_id: $fixture_invoice_address_id,
                                                                         variant1_id: $fixture1_variant_id,
                                                                         variant2_id: $fixture2_variant_id,
                                                                         variant3_id: $fixture3_variant_id,
                                                                         idempotency_key: uuid_gen.generate})
    response = JSON.parse(last_response.body)
    assert_equal 201, last_response.status
    # assert_equal $fixture_address_id, Shipment.where(order_id: response['id']).address_id
    assert_equal $fixture_invoice_address_id, Order[response['id']].invoice.address_id
    assert_equal nr_of_orders + 2, Order.where(user_id: $test_user_id).count

    post 'orders', order_renderer_with_new_addresses.result_with_hash({variant1_id: $fixture1_variant_id,
                                                                       variant2_id: $fixture2_variant_id,
                                                                       variant3_id: $fixture3_variant_id,
                                                                       idempotency_key: uuid_gen.generate})
    response = JSON.parse(last_response.body)
    assert_equal 201, last_response.status
    assert_equal nr_of_addresses + 2, Address.all.count
    # assert_equal Address[Address.all.count - 2].id, Order[response['id']].invoice.address_id
    # assert_equal Address.last.id, Shipment.where(order_id: response['order']['id']).address_id
    assert_equal nr_of_orders + 3, Order.where(user_id: $test_user_id).count
  end
end
