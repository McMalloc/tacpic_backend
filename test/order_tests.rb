require_relative './test_helper'
require 'savon/mock/spec_helper'

describe 'Creating Orders' do
  include Savon::SpecHelper

  before do
    header 'Authorization', 'Bearer ' + $token
    header 'Content-Type', 'application/json'
    # savon.mock!

    # savon.expects(:checkout_shopping_cart_png)
    #      .with(message: :any)
    #      .returns(File.read(File.join(ENV['APPLICATION_BASE'],
    #                                   '/test/mock_wsdl_response_buewa.xml')))
  end

  after do
    # savon.unmock!
    if last_response.status === 500 then
      puts "\nError:"
      puts get_body(last_response)
      puts "\n - - - - - - - - - "
    end
  end

  it 'should create a new order, new address and reject its duplicate' do
    test_data = read_test_data('order_1', {
                                 key: ('a'..'z').to_a.sample(8).join,
                                 invoice_address: 'null',
                                 shipping_address: read_test_data('address', last_name: 'Ketchum', id: 'null')
                               })
    post 'orders', test_data
    assert_equal 201, last_response.status
    assert_equal 680 + 200, get_body(last_response)['total_gross']
    assert present_in_pdf(Order.last.invoices.last.get_pdf_path, 'Ketchum')

    post 'orders', test_data
    assert_equal 409, last_response.status
  end

  it 'should create a new order with an existing address' do
    test_data = read_test_data('order_1', {
                                 key: ('a'..'z').to_a.sample(8).join,
                                 invoice_address: 'null',
                                 shipping_address: read_test_data('address', last_name: 'Willbeignored',
                                                                             id: $test_user.addresses.first.id)
                               })
    n_addresses = Address.all.count
    n_invoices = count_files 'files/invoices'
    n_receipts = count_files 'files/shipment_receipts'
    post 'orders', test_data

    assert present_in_pdf(Order.last.invoices.last.get_pdf_path, 'Eich')
    # assert_equal n_invoices + 1, count_files('files/invoices')
    assert_equal n_receipts, count_files('files/shipment_receipts')
    assert_equal n_addresses, Address.all.count
  end

  it 'should create an invoice and a shipping document with respective vouchers, and a new order' do
    # neccessary because of a Savon bug
    # https://github.com/savonrb/savon/issues/795
    # savon.expects(:checkout_shopping_cart_png)
    #      .with(message: :any)
    #      .returns(File.read(File.join(ENV['APPLICATION_BASE'],
    #                                   '/test/mock_wsdl_response_standard.xml')))

    random_name = Faker::Name.last_name
    test_data = read_test_data('order_1', {
                                 key: ('a'..'z').to_a.sample(32).join,
                                 invoice_address: read_test_data('address',
                                                                 last_name: random_name, id: 'null'),
                                 shipping_address: read_test_data('address', last_name: 'Willbeignored',
                                                                             id: $test_user.addresses.first.id)
                               })
    n_addresses = Address.all.count
    n_invoices = count_files 'files/invoices'
    n_receipts = count_files 'files/shipment_receipts'
    post 'orders', test_data
    assert_equal 201, last_response.status

    assert present_in_pdf(Order.last.invoices.last.get_pdf_path, random_name)
    assert_equal Order.last.total_gross, 880
    assert present_in_pdf(Order.last.invoices.last.get_pdf_path, Order.last.invoices.last.invoice_number)
    assert present_in_pdf(Order.last.invoices.last.get_pdf_path, '8,80€') # gross total
    assert present_in_pdf(Order.last.invoices.last.get_pdf_path, '6,36€') # net total
    assert present_in_pdf(Order.last.invoices.last.get_pdf_path, '1,87€') # net single
    # cannot grep the address in the voucher, since it is a placeholder
    # assert present_in_pdf(Shipment.where(order_id: Order.last.id).first.get_pdf_path, $test_user.addresses.first.last_name)
    assert_equal n_addresses + 1, Address.all.count
    assert_equal n_invoices + 1, count_files('files/invoices')
    assert_equal n_receipts + 1, count_files('files/shipment_receipts')
    assert_equal Address.last.last_name, random_name
  end
end
