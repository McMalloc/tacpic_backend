require_relative './test_helper'

describe 'Creating Addresses' do
  before do
    header 'Authorization', 'Bearer ' + $token
    header 'Content-Type', 'application/json'
  end

  after do

  end

  it 'should create a new address' do
    test_data = read_test_data('address', last_name: 'Ketchum', id: 'null')
    post 'users/addresses', test_data
    assert_equal 201, last_response.status
    assert_equal 'Ketchum', Address.last.last_name
  end

  it 'should not create an incomplete address' do
    test_data = read_test_data('address', last_name: '', id: 'null')
    post 'users/addresses', test_data
    assert_equal 500, last_response.status
  end

  it 'should update an existing address' do
    test_data = read_test_data('address', last_name: 'Lance', id: 'null')
    post 'users/addresses', test_data
    assert_equal 201, last_response.status
    assert_equal 'Lance', Address.last.last_name
    nAddresses = Address.all.count

    test_data = read_test_data('address', last_name: 'Ketchum', id: Address.last.id)
    post "users/addresses/#{Address.last.id}", test_data
    assert_equal 200, last_response.status
    assert_equal nAddresses, Address.all.count
    assert_equal 'Ketchum', Address.last.last_name
  end
end
